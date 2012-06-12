class ScoutRails::TransactionSample
  attr_reader :metric_name, :total_call_time, :metrics, :meta, :uri
  
  def initialize(uri,metric_name,total_call_time,metrics)
    @uri = uri
    @metric_name = metric_name
    @total_call_time = total_call_time
    @metrics = metrics
  end
end