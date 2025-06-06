#!/usr/bin/env ruby

# This script starts a simplified version of the API server
require 'fileutils'

puts "Starting the simplified RESTful API server..."
puts "Press Ctrl+C to stop the server"

# Create necessary directories
FileUtils.mkdir_p('log')
FileUtils.mkdir_p('vendor/bundle')

# Check if bundler is installed
unless system("gem list -i bundler > /dev/null 2>&1")
  puts "Bundler is not installed. Installing bundler..."
  system("gem install bundler")
end

# Create a simplified Gemfile with minimal dependencies
unless File.exist?('Gemfile.simple')
  puts "Creating simplified Gemfile..."
  File.open('Gemfile.simple', 'w') do |f|
    f.puts "source 'https://rubygems.org'"
    f.puts "ruby '2.6.10'"
    f.puts "gem 'sinatra', '~> 2.2.0'"
    f.puts "gem 'sinatra-contrib', '~> 2.2.0'"
    f.puts "gem 'json', '~> 2.6.0'"
    f.puts "gem 'rack', '~> 2.2.4'"
    f.puts "gem 'puma', '~> 5.6.4'"
  end
end

# Install dependencies locally
puts "Installing minimal dependencies locally..."
system("bundle install --gemfile=Gemfile.simple --path vendor/bundle")

# Start the server with the simplified configuration
puts "Starting server on http://localhost:4567"
exec("bundle exec --gemfile=Gemfile.simple rackup config_simple.ru -p 4567 -o 0.0.0.0")
