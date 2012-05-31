class ScoutRails::TransactionSample
  attr_accessor :metric_name, :total_call_time, :metrics, :meta
  
  def initialize(metric_name,total_call_time,metrics)
    self.metric_name = metric_name
    self.total_call_time = total_call_time
    self.metrics = metrics
  end
end