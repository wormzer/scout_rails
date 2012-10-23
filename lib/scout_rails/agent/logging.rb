# Contains methods specific to logging (initializing the log file, applying the log level, applying the log format, etc.)
module ScoutRails
  class Agent
    module Logging
      def log_path
        "#{environment.root}/log"
      end
      
      def init_logger
        @log_file = "#{log_path}/scout_rails.log"
        begin 
          @logger = Logger.new(@log_file) 
          @logger.level = log_level
          apply_log_format
        rescue Exception => e
          @logger = Logger.new(STDOUT)
          apply_log_format
          @logger.error "Unable to access log file: #{e.message}"
        end
        @logger
      end

      def apply_log_format
        def logger.format_message(severity, timestamp, progname, msg)
          # since STDOUT isn't exclusive like the scout_rails.log file, apply a prefix.
          prefix = @logdev.dev == STDOUT ? "scout_rails " : ''
          prefix + "[#{timestamp.strftime("%m/%d/%y %H:%M:%S %z")} #{Socket.gethostname} (#{$$})] #{severity} : #{msg}\n"
        end
      end

      def log_level
        case config.settings['log_level'].downcase
          when "debug" then Logger::DEBUG
          when "info" then Logger::INFO
          when "warn" then Logger::WARN
          when "error" then Logger::ERROR
          when "fatal" then Logger::FATAL
          else Logger::INFO
        end
      end
    end # module Logging
    include Logging
  end # class Agent
end # moudle ScoutRails