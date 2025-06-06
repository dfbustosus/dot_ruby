#!/usr/bin/env ruby

# This script installs the minimal required gems and starts a simple RESTful API
puts "Setting up minimal RESTful API..."

# Install required gems if not already installed
required_gems = ['sinatra', 'json', 'webrick']

required_gems.each do |gem_name|
  unless system("gem list -i #{gem_name} > /dev/null 2>&1")
    puts "Installing #{gem_name} gem..."
    system("gem install #{gem_name} --user-install")
  end
end

puts "Starting minimal RESTful API server..."
puts "Server will be available at http://localhost:4567"
puts "Press Ctrl+C to stop the server"

# Run the Sinatra application
exec("ruby minimal_api.rb")
