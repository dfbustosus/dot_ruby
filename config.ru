require 'rubygems'
require 'bundler'

# Setup load paths
$: << File.expand_path('../', __FILE__)
$: << File.expand_path('../lib', __FILE__)

# Require the application file
require './config/application'

# Initialize the database connection
Database.connect

# Use Rack::Deflater for compression
use Rack::Deflater

# Use Puma web server in production
if ENV['APP_ENV'] == 'production'
  require 'rack/timeout'
  use Rack::Timeout, service_timeout: 15
end

# Run the application
run Application
