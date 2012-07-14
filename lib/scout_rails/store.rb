# The store encapsolutes the logic that (1) saves instrumented data by Metric name to memory and (2) maintains a stack (just an Array)
# of instrumented methods that are being called. It's accessed via +ScoutRails::Agent.instance.store+. 
class ScoutRails::Store
  attr_accessor :metric_hash
  attr_accessor :transaction_hash
  attr_accessor :stack
  attr_accessor :sample
  attr_reader :transaction_sample_lock
  
  def initialize
    @metric_hash = Hash.new
    # Stores aggregate metrics for the current transaction. When the transaction is finished, metrics
    # are merged with the +metric_hash+.
    @transaction_hash = Hash.new
    @stack = Array.new
    # ensure background thread doesn't manipulate transaction sample while the store is.
    @transaction_sample_lock = Mutex.new
  end
  
  # Called when the last stack item completes for the current transaction to clear
  # for the next run.
  def reset_transaction!
    Thread::current[:ignore_transaction] = nil
    Thread::current[:scout_scope_name] = nil
    @transaction_hash = Hash.new
    @stack = Array.new
  end
  
  def ignore_transaction!
    Thread::current[:ignore_transaction] = true
  end
  
  # Called at the start of Tracer#instrument:
  # (1) Either finds an existing MetricStats object in the metric_hash or 
  # initialize a new one. An existing MetricStats object is present if this +metric_name+ has already been instrumented.
  # (2) Adds a StackItem to the stack. This StackItem is returned and later used to validate the item popped off the stack
  # when an instrumented code block completes.
  def record(metric_name)
    item = ScoutRails::StackItem.new(metric_name)
    stack << item
    item
  end
  
  def stop_recording(sanity_check_item, options={})
    item = stack.pop
    stack_empty = stack.empty?
    # if ignoring the transaction, the item is popped but nothing happens. 
    if Thread::current[:ignore_transaction]
      return
    end
    # unbalanced stack check - unreproducable cases have seen this occur. when it does, sets a Thread variable 
    # so we ignore further recordings. +Store#reset_transaction!+ resets this. 
    if item != sanity_check_item
      ScoutRails::Agent.instance.logger.warn "Scope [#{Thread::current[:scout_scope_name]}] Popped off stack: #{item.inspect} Expected: #{sanity_check_item.inspect}. Aborting."
      ignore_transaction!
      return
    end
    duration = Time.now - item.start_time
    if last=stack.last
      last.children_time += duration
    end
    meta = ScoutRails::MetricMeta.new(item.metric_name, :desc => options[:desc])
    meta.scope = nil if stack_empty
    
    # add backtrace for slow calls ... how is exclusive time handled?
    if duration > 0.5 and !stack_empty
      meta.extra = {:backtrace => caller.find_all { |c| c =~ /\/app\//}}
    end
    stat = transaction_hash[meta] || ScoutRails::MetricStats.new(!stack_empty)
    
    stat.update!(duration,duration-item.children_time)
    transaction_hash[meta] = stat   
    
    # Uses controllers as the entry point for a transaction. Otherwise, stats are ignored.
    if stack_empty and meta.metric_name.match(/\AController\//)
      aggs=aggregate_calls(transaction_hash.dup,meta)
      store_sample(options[:uri],transaction_hash.dup.merge(aggs),meta,stat)  
      # deep duplicate  
      duplicate = aggs.dup
      duplicate.each_pair do |k,v|
        duplicate[k.dup] = v.dup
      end  
      merge_data(duplicate.merge({meta.dup => stat.dup})) # aggregrates + controller 
    end
  end
  
  # Returns the top-level category names used in the +metrics+ hash.
  def categories(metrics)
    cats = Set.new
    metrics.keys.each do |meta|
      next if meta.scope.nil? # ignore controller
      if match=meta.metric_name.match(/\A([\w|\d]+)\//)
        cats << match[1]
      end
    end # metrics.each
    cats
  end
  
  # Takes a metric_hash of calls and generates aggregates for ActiveRecord and View calls.
  def aggregate_calls(metrics,parent_meta)
    categories = categories(metrics)
    aggregates = {}
    categories.each do |cat|
      agg_meta=ScoutRails::MetricMeta.new("#{cat}/all")
      agg_meta.scope = parent_meta.metric_name
      agg_stats = ScoutRails::MetricStats.new
      metrics.each do |meta,stats|
        if meta.metric_name =~ /\A#{cat}\//
          agg_stats.combine!(stats) 
        end
      end # metrics.each
      aggregates[agg_meta] = agg_stats unless agg_stats.call_count.zero?
    end # categories.each    
    aggregates
  end
  
  # Stores the slowest transaction. This will be sent to the server.
  def store_sample(uri,transaction_hash,parent_meta,parent_stat,options = {})    
    @transaction_sample_lock.synchronize do
      if parent_stat.total_call_time >= 2 and (@sample.nil? or (@sample and parent_stat.total_call_time > @sample.total_call_time))
        @sample = ScoutRails::TransactionSample.new(uri,parent_meta.metric_name,parent_stat.total_call_time,transaction_hash.dup)
      end
    end
  end
  
  # Finds or creates the metric w/the given name in the metric_hash, and updates the time. Primarily used to 
  # record sampled metrics. For instrumented methods, #record and #stop_recording are used.
  #
  # Options:
  # :scope => If provided, overrides the default scope. 
  # :exclusive_time => Sets the exclusive time for the method. If not provided, uses +call_time+.
  def track!(metric_name,call_time,options = {})
     meta = ScoutRails::MetricMeta.new(metric_name)
     meta.scope = options[:scope] if options.has_key?(:scope)
     stat = metric_hash[meta] || ScoutRails::MetricStats.new
     stat.update!(call_time,options[:exclusive_time] || call_time)
     metric_hash[meta] = stat
  end
  
  # Combines old and current data
  def merge_data(old_data)
    old_data.each do |old_meta,old_stats|
      if stats = metric_hash[old_meta]
        metric_hash[old_meta] = stats.combine!(old_stats)
      else
        metric_hash[old_meta] = old_stats
      end
    end
    metric_hash
  end
  
  # Merges old and current data, clears the current in-memory metric hash, and returns
  # the merged data
  def merge_data_and_clear(old_data)
    merged = merge_data(old_data)
    self.metric_hash =  {}
    merged
  end
end # class Store