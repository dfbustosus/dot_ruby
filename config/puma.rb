#!/usr/bin/env puma

# Load environment variables
require 'dotenv'
Dotenv.load('.env.production', '.env')

# The directory to operate out of
directory File.expand_path('..', __dir__)

# Set the environment
environment ENV['APP_ENV'] || 'production'

# Set the port and host
port ENV['PORT'] || 4567
bind "tcp://#{ENV['HOST'] || '0.0.0.0'}:#{ENV['PORT'] || 4567}"

# Puma can serve each request in a thread from an internal thread pool
# The `threads` method setting takes two numbers: a minimum and maximum
# Any libraries that use thread pools should be configured to match
# the maximum value specified for Puma
threads_count = ENV.fetch('PUMA_THREADS') { 5 }.to_i
threads threads_count, threads_count

# Number of workers (processes)
# Workers do not work with JRuby or Windows
workers ENV.fetch('WEB_CONCURRENCY') { 2 }.to_i

# Preload the application for better performance
# This setting is not compatible with phased restart
preload_app!

# Use the `on_worker_boot` hook to load code that needs to be
# loaded for each worker but not for the master
on_worker_boot do
  # Re-establish database connections for each worker
  require_relative '../config/database'
  Database.connect
end

# Allow puma to be restarted by `rails restart` command
plugin :tmp_restart

# Redirect STDOUT and STDERR to files specified
stdout_redirect 'log/puma.stdout.log', 'log/puma.stderr.log', true

# PID file location
pidfile ENV.fetch('PIDFILE') { 'tmp/pids/server.pid' }

# Control app
activate_control_app 'unix://tmp/sockets/pumactl.sock', { auth_token: ENV['PUMA_CONTROL_TOKEN'] }

# Specifies the number of seconds to wait for requests to complete
# when shutting down the server
shutdown_grace_period 10

# Set the timeout for worker shutdown
worker_shutdown_timeout 30

# Set the timeout for worker boot
worker_timeout 60

# Log JSON format for better parsing
log_formatter do |str|
  "#{Time.now.iso8601} [PUMA] #{str}\n"
end
