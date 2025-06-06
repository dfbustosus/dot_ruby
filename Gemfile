source 'https://rubygems.org'

ruby '2.6.10'

# Sinatra for lightweight web framework
gem 'sinatra', '~> 2.2.0'
gem 'sinatra-contrib', '~> 2.2.0'

# For JSON handling
gem 'json', '~> 2.6.0'

# For request parsing
gem 'rack', '~> 2.2.4'

# For cross-origin requests
gem 'rack-cors', '~> 1.1.1'

# For environment variables
gem 'dotenv', '~> 2.7.6'

# For logging
gem 'logger', '~> 1.5.1'

# Database gems
gem 'sequel', '~> 5.42.0'

# Use SQLite for development
gem 'sqlite3', '~> 1.4.2'

# PostgreSQL adapter (optional for production)
group :production do
  gem 'pg', '~> 1.2.3'
end

# For performance monitoring
gem 'newrelic_rpm', '~> 8.0.0'

# For caching
gem 'redis', '~> 4.5.1'

# For background jobs
gem 'sidekiq', '~> 6.4.0'

# For security
gem 'rack-protection', '~> 2.2.0'
gem 'bcrypt', '~> 3.1.16'

# For API documentation
gem 'yard', '~> 0.9.26'

# For production web server
gem 'puma', '~> 5.6.4'

# Environment-specific gems
group :development, :test do
  gem 'rspec', '~> 3.10.0'
  gem 'rack-test', '~> 1.1.0'
  gem 'rubocop', '~> 1.25.0'
  gem 'pry', '~> 0.14.1'
end

group :production do
  gem 'rack-timeout', '~> 0.6.0'
  gem 'rack-attack', '~> 6.6.0'
end
