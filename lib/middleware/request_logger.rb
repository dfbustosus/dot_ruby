require 'logger'

class RequestLogger
  def initialize(app, options = {})
    @app = app
    log_file = options[:log_file] || File.open("log/#{ENV['APP_ENV'] || 'development'}.log", 'a')
    @logger = Logger.new(log_file)
    @logger.level = options[:log_level] || Logger::INFO
  end

  def call(env)
    start_time = Time.now
    status, headers, body = @app.call(env)
    end_time = Time.now
    
    log_request(env, status, start_time, end_time)
    
    [status, headers, body]
  end

  private

  def log_request(env, status, start_time, end_time)
    request = Rack::Request.new(env)
    duration = ((end_time - start_time) * 1000).round(2)
    
    log_entry = {
      method: request.request_method,
      path: request.path,
      params: request.params.reject { |k, _| k == 'password' || k == 'password_confirmation' },
      ip: request.ip,
      status: status,
      duration: "#{duration}ms",
      timestamp: Time.now.utc.iso8601
    }
    
    # Color-code based on status code
    log_level = case status
                when 200..399 then :info
                when 400..499 then :warn
                else :error
                end
    
    @logger.send(log_level, log_entry.to_json)
  end
end
