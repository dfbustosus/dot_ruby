#!/usr/bin/env ruby

# This script starts the production-ready API server
require 'fileutils'
require 'dotenv'
require 'optparse'

# Load environment variables
Dotenv.load

# Default options
options = {
  environment: ENV['APP_ENV'] || 'development',
  port: ENV['PORT'] || 4567,
  host: ENV['HOST'] || '0.0.0.0',
  server: 'puma',
  daemonize: false,
  pid_file: nil,
  log_file: nil
}

# Parse command line options
OptionParser.new do |opts|
  opts.banner = "Usage: ruby start_server.rb [options]"
  
  opts.on("-e", "--environment ENV", "Set the environment (default: #{options[:environment]})") do |env|
    options[:environment] = env
  end
  
  opts.on("-p", "--port PORT", "Set the port (default: #{options[:port]})") do |port|
    options[:port] = port
  end
  
  opts.on("-o", "--host HOST", "Set the host (default: #{options[:host]})") do |host|
    options[:host] = host
  end
  
  opts.on("-s", "--server SERVER", "Set the server (default: #{options[:server]})") do |server|
    options[:server] = server
  end
  
  opts.on("-d", "--daemonize", "Run as daemon in the background") do
    options[:daemonize] = true
  end
  
  opts.on("--pid FILE", "Store PID in FILE (default: tmp/pids/server.pid)") do |file|
    options[:pid_file] = file
  end
  
  opts.on("--log FILE", "Write logs to FILE (default: log/[environment].log)") do |file|
    options[:log_file] = file
  end
  
  opts.on("-h", "--help", "Show this help") do
    puts opts
    exit
  end
end.parse!

# Set default PID and log files if not specified
options[:pid_file] ||= "tmp/pids/server.pid"
options[:log_file] ||= "log/#{options[:environment]}.log"

# Ensure directories exist
FileUtils.mkdir_p(File.dirname(options[:pid_file]))
FileUtils.mkdir_p(File.dirname(options[:log_file]))

# Check if bundler is installed
unless system("gem list -i bundler > /dev/null 2>&1")
  puts "Bundler is not installed. Installing bundler..."
  system("gem install bundler")
end

# Create vendor directory for local gems if it doesn't exist
FileUtils.mkdir_p('vendor/bundle')

# Install dependencies locally to avoid permission issues
puts "Installing dependencies locally..."
system("bundle install --path vendor/bundle")

# Skip database migrations in initial startup to avoid dependency issues
# We'll handle migrations separately after gems are installed

# Build the command
command = ["bundle exec rackup"]
command << "-s #{options[:server]}"
command << "-p #{options[:port]}"
command << "-o #{options[:host]}"
command << "-E #{options[:environment]}"
command << "-D" if options[:daemonize]
command << "--pid #{options[:pid_file]}" if options[:daemonize]
command << ">> #{options[:log_file]} 2>&1" if options[:daemonize]

# Print startup message
if options[:daemonize]
  puts "Starting server in #{options[:environment]} mode as daemon..."
  puts "PID file: #{options[:pid_file]}"
  puts "Log file: #{options[:log_file]}"
  puts "To stop the server: kill -TERM $(cat #{options[:pid_file]})"
else
  puts "Starting server in #{options[:environment]} mode..."
  puts "Press Ctrl+C to stop the server"
  puts "Server will be available at http://#{options[:host] == '0.0.0.0' ? 'localhost' : options[:host]}:#{options[:port]}"
end

# Start the server
exec(command.join(" "))
