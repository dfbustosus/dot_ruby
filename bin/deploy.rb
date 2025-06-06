#!/usr/bin/env ruby

# Production deployment script
require 'fileutils'
require 'dotenv'
require 'optparse'

# Default options
options = {
  environment: 'production',
  migrate: true,
  restart: true,
  backup: true
}

# Parse command line options
OptionParser.new do |opts|
  opts.banner = "Usage: ruby deploy.rb [options]"
  
  opts.on("-e", "--environment ENV", "Set the environment (default: production)") do |env|
    options[:environment] = env
  end
  
  opts.on("--[no-]migrate", "Run database migrations (default: true)") do |migrate|
    options[:migrate] = migrate
  end
  
  opts.on("--[no-]restart", "Restart the server after deployment (default: true)") do |restart|
    options[:restart] = restart
  end
  
  opts.on("--[no-]backup", "Backup the database before migrations (default: true)") do |backup|
    options[:backup] = backup
  end
  
  opts.on("-h", "--help", "Show this help") do
    puts opts
    exit
  end
end.parse!

# Set environment variable
ENV['APP_ENV'] = options[:environment]

# Load environment variables
Dotenv.load(".env.#{options[:environment]}", '.env')

# Ensure we're in the application root directory
APP_ROOT = File.expand_path('..', __dir__)
Dir.chdir(APP_ROOT)

# Helper method to run commands
def run(command)
  puts "Running: #{command}"
  system(command) or raise "Command failed: #{command}"
end

# Step 1: Pull latest code (assuming Git)
puts "=== Pulling latest code ==="
run "git pull origin main"

# Step 2: Install dependencies
puts "=== Installing dependencies ==="
run "bundle install --without development test"

# Step 3: Backup database if requested
if options[:backup] && options[:migrate]
  puts "=== Backing up database ==="
  timestamp = Time.now.strftime("%Y%m%d%H%M%S")
  backup_dir = "#{APP_ROOT}/db/backups"
  FileUtils.mkdir_p(backup_dir)
  
  if ENV['DATABASE_URL']&.start_with?('postgres')
    # PostgreSQL backup
    db_url = ENV['DATABASE_URL']
    uri = URI.parse(db_url)
    db_name = uri.path.sub(/^\//, '')
    run "PGPASSWORD=#{uri.password} pg_dump -h #{uri.host} -p #{uri.port || 5432} -U #{uri.user} -F c -b -v -f #{backup_dir}/backup_#{timestamp}.pgdump #{db_name}"
  elsif ENV['DATABASE_URL']&.start_with?('mysql')
    # MySQL backup
    db_url = ENV['DATABASE_URL']
    uri = URI.parse(db_url)
    db_name = uri.path.sub(/^\//, '')
    run "mysqldump -h #{uri.host} -P #{uri.port || 3306} -u #{uri.user} -p#{uri.password} #{db_name} > #{backup_dir}/backup_#{timestamp}.sql"
  else
    puts "Skipping backup: Unsupported database or no DATABASE_URL provided"
  end
end

# Step 4: Run migrations if requested
if options[:migrate]
  puts "=== Running database migrations ==="
  require_relative '../config/database'
  Database.migrate
end

# Step 5: Precompile assets if any
puts "=== Precompiling assets ==="
FileUtils.mkdir_p("#{APP_ROOT}/public/assets")
# Add asset compilation here if needed

# Step 6: Update crontab if needed
if File.exist?("#{APP_ROOT}/config/schedule.rb")
  puts "=== Updating cron jobs ==="
  run "bundle exec whenever --update-crontab"
end

# Step 7: Restart the server if requested
if options[:restart]
  puts "=== Restarting the server ==="
  pid_file = "#{APP_ROOT}/tmp/pids/server.pid"
  
  if File.exist?(pid_file)
    pid = File.read(pid_file).strip
    begin
      Process.kill("TERM", pid.to_i)
      puts "Sent TERM signal to process #{pid}"
      sleep 5 # Give it time to shut down gracefully
    rescue Errno::ESRCH
      puts "Process #{pid} not found, removing stale PID file"
    end
    FileUtils.rm_f(pid_file)
  end
  
  # Start the server in daemon mode
  run "ruby start_server.rb -e #{options[:environment]} -d"
end

puts "=== Deployment completed successfully ==="
