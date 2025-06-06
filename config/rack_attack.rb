require 'rack/attack'

# Configure Rack::Attack for security
class Rack::Attack
  # Cache store for throttling
  self.cache.store = if ENV['REDIS_URL']
                        Redis.new(url: ENV['REDIS_URL'])
                      else
                        ActiveSupport::Cache::MemoryStore.new
                      end

  # Allow all requests from localhost
  safelist('allow from localhost') do |req|
    # Localhost IPv4 and IPv6
    '127.0.0.1' == req.ip || '::1' == req.ip
  end

  # Block suspicious requests
  blocklist('block suspicious requests') do |req|
    # Block requests with suspicious user agents
    req.user_agent =~ %r{(nmap|nikto|sqlmap|scanbot|semrush|censys|masscan)}i
  end

  # Throttle high volumes of requests by IP address
  throttle('req/ip', limit: (ENV['RATE_LIMIT'] || 100).to_i, period: 1.minute) do |req|
    req.ip unless req.path.start_with?('/public/')
  end

  # Throttle login attempts by IP address
  throttle('logins/ip', limit: 5, period: 20.minutes) do |req|
    if req.path == '/api/auth/login' && req.post?
      req.ip
    end
  end

  # Throttle login attempts by email
  throttle('logins/email', limit: 5, period: 20.minutes) do |req|
    if req.path == '/api/auth/login' && req.post?
      # Extract the email from the request body
      req_body = JSON.parse(req.body.read)
      req.body.rewind # Be kind and rewind
      req_body['email'].to_s.downcase if req_body['email']
    end
  end

  # Throttle API token requests
  throttle('api/token', limit: 10, period: 1.hour) do |req|
    if req.path == '/api/auth/token' && req.post?
      req.ip
    end
  end

  # Block IP addresses that make too many bad requests
  Rack::Attack.blocklist('fail2ban pentesters') do |req|
    Rack::Attack::Fail2Ban.filter("pentesters-#{req.ip}", maxretry: 3, findtime: 10.minutes, bantime: 1.hour) do
      # Return true for 404s for php files
      req.path.end_with?('.php') ||
        req.path.include?('wp-admin') ||
        req.path.include?('wp-login')
    end
  end

  # Custom response for throttled requests
  self.throttled_response = lambda do |env|
    now = Time.now
    match_data = env['rack.attack.match_data']

    headers = {
      'Content-Type' => 'application/json',
      'Retry-After' => (match_data[:period] - (now.to_i % match_data[:period])).to_s
    }

    [
      429,
      headers,
      [{ 
        error: 'Throttle limit reached. Please retry later.',
        retry_after: headers['Retry-After']
      }.to_json]
    ]
  end
end
