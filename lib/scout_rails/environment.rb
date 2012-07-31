# Used to retrieve environment information for this application.
module ScoutRails
  class Environment
    def env
      @env ||= case framework
               when :rails then RAILS_ENV.dup
               when :rails3 then Rails.env
               when :sinatra
                 ENV['RACK_ENV'] || ENV['RAILS_ENV'] || 'development'
               end
    end
    
    def framework
      @framework ||= case
                      when defined?(::Rails) && defined?(ActionController)
                        if Rails::VERSION::MAJOR < 3
                          :rails
                        else
                          :rails3
                        end
                      when defined?(::Sinatra) && defined?(::Sinatra::Base) then :sinatra
                      else :ruby
                      end
    end
    
    def processors
      return @processors if @processors
      unless @processors
        proc_file = '/proc/cpuinfo'
        if !File.exist?(proc_file)
          @processors = 1
        elsif `cat #{proc_file} | grep 'model name' | wc -l` =~ /(\d+)/
          @processors = $1.to_i
        end
        if @processors < 1
          @processors = 1
        end 
      end
      @processors
    end
    
    def root
      if framework == :rails
        RAILS_ROOT.to_s
      elsif framework == :rails3
        Rails.root
      elsif framework == :sinatra
        Sinatra::Application.root
      else
        '.'
      end
    end
    
    def app_server
      @app_server ||= if thin? then :thin
                    elsif passenger? then :passenger
                    elsif webrick? then :webrick
                    elsif unicorn? then :unicorn
                    else nil
                    end
    end
    
    ### app server related-checks
    
    def thin?
      if defined?(::Thin) && defined?(::Thin::Server)
        # Ensure Thin is actually initialized. It could just be required and not running.
        ObjectSpace.each_object(Thin::Server) { |x| return true }
        false
      end
    end
    
    def unicorn?
      if defined?(::Unicorn) && defined?(::Unicorn::HttpServer)
        # Ensure Unicorn is actually initialized. It could just be required and not running.
        ObjectSpace.each_object(::Unicorn::HttpServer) { |x| return true }
        false
      end
    end
    
    # Called via +#forking?+ since Passenger forks. Adds an event listener to start the worker thread
    # inside the passenger worker process.
    # Background: http://www.modrails.com/documentation/Users%20guide%20Nginx.html#spawning%5Fmethods%5Fexplained
    def passenger?
      (defined?(::Passenger) && defined?(::Passenger::AbstractServer)) || defined?(::IN_PHUSION_PASSENGER)
    end
    
    def webrick?
      defined?(::WEBrick) && defined?(::WEBrick::VERSION)
    end
    
    def unicorn?
      if defined?(::Unicorn) && defined?(::Unicorn::HttpServer)
        # ensure Unicorn is actually initialized. 
        ObjectSpace.each_object(::Unicorn::HttpServer) { |x| return true }
      end
    end
    
    # If forking, don't start worker thread in the master process. Since it's started as a Thread, it won't survive
    # the fork. 
    def forking?
      passenger? or unicorn?
    end
    
    ### ruby checks
    
    def rubinius?
      RUBY_VERSION =~ /rubinius/i
    end

    def jruby?
      defined?(JRuby)
    end
    
    ### framework checks

    def sinatra?
      defined?(Sinatra::Application)
    end

  end # class Environemnt
end