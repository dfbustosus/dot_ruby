require 'redis'

class RateLimiter
  def initialize(app, options = {})
    @app = app
    @limit = options[:limit] || 100
    @period = options[:period] || 3600 # 1 hour in seconds
    @redis = if ENV['REDIS_URL']
               Redis.new(url: ENV['REDIS_URL'])
             else
               nil # Redis is optional, if not available, rate limiting is disabled
             end
  end

  def call(env)
    request = Rack::Request.new(env)
    
    # Skip rate limiting if Redis is not available or for certain paths
    if @redis.nil? || whitelisted_path?(request.path)
      return @app.call(env)
    end
    
    client_ip = request.ip
    key = "rate_limit:#{client_ip}"
    
    # Get current count
    count = @redis.get(key).to_i
    
    # If first request, set expiry
    if count == 0
      @redis.setex(key, @period, 1)
      count = 1
    else
      # Increment count
      count = @redis.incr(key)
    end
    
    # Set headers with rate limit info
    headers = {
      'X-RateLimit-Limit' => @limit.to_s,
      'X-RateLimit-Remaining' => (@limit - count).to_s,
      'X-RateLimit-Reset' => (@redis.ttl(key) + Time.now.to_i).to_s
    }
    
    # If over limit, return 429 Too Many Requests
    if count > @limit
      return [
        429, 
        headers.merge('Content-Type' => 'application/json'),
        [{ error: 'Rate limit exceeded. Please try again later.' }.to_json]
      ]
    end
    
    # Otherwise, call the app
    status, app_headers, body = @app.call(env)
    
    # Merge rate limit headers with app headers
    [status, app_headers.merge(headers), body]
  end
  
  private
  
  def whitelisted_path?(path)
    # Don't rate limit static assets or health checks
    path.start_with?('/public/') || path == '/health'
  end
end
