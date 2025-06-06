#!/usr/bin/env ruby

# Standalone RESTful API using only standard libraries
require 'webrick'
require 'json'
require 'logger'

# Create logger
logger = Logger.new(STDOUT)
logger.level = Logger::INFO

# In-memory data store
ITEMS = [
  { id: 1, name: 'Item 1', description: 'Description for item 1' },
  { id: 2, name: 'Item 2', description: 'Description for item 2' }
]

# Helper method to find an item by ID
def find_item(id)
  ITEMS.find { |item| item[:id] == id.to_i }
end

# Helper method to generate a new ID
def next_id
  ITEMS.map { |item| item[:id] }.max + 1 rescue 1
end

# Helper method to parse JSON request body
def parse_json_body(request)
  body = request.body
  return {} if body.nil? || body.empty?
  
  begin
    JSON.parse(body, symbolize_names: true)
  rescue JSON::ParserError
    {}
  end
end

# Helper method to send JSON response
def json_response(response, status, data)
  response.status = status
  response['Content-Type'] = 'application/json'
  response.body = data.to_json
end

# Create server
server = WEBrick::HTTPServer.new(
  Port: 4567,
  BindAddress: '0.0.0.0',
  Logger: logger,
  AccessLog: [
    [logger, WEBrick::AccessLog::COMBINED_LOG_FORMAT]
  ]
)

# Define routes

# GET / - Welcome message
server.mount_proc '/' do |request, response|
  json_response(response, 200, { message: 'Welcome to the RESTful API', version: '1.0.0' })
end

# GET /api/items - List all items
server.mount_proc '/api/items' do |request, response|
  if request.request_method == 'GET'
    json_response(response, 200, ITEMS)
  elsif request.request_method == 'POST'
    begin
      data = parse_json_body(request)
      
      if data[:name].nil? || data[:name].empty?
        json_response(response, 400, { error: 'Name is required' })
      else
        new_item = {
          id: next_id,
          name: data[:name],
          description: data[:description] || ''
        }
        
        ITEMS << new_item
        json_response(response, 201, new_item)
      end
    rescue => e
      logger.error("Error creating item: #{e.message}")
      json_response(response, 500, { error: e.message })
    end
  else
    response.status = 405
  end
end

# GET/PUT/DELETE /api/items/:id - Item operations
server.mount_proc /\/api\/items\/(\d+)/ do |request, response, path_params|
  id = path_params[0].to_i
  item = find_item(id)
  
  if item.nil?
    json_response(response, 404, { error: 'Item not found' })
  else
    case request.request_method
    when 'GET'
      json_response(response, 200, item)
    when 'PUT'
      begin
        data = parse_json_body(request)
        
        item[:name] = data[:name] if data[:name]
        item[:description] = data[:description] if data[:description]
        
        json_response(response, 200, item)
      rescue => e
        logger.error("Error updating item: #{e.message}")
        json_response(response, 500, { error: e.message })
      end
    when 'DELETE'
      ITEMS.delete(item)
      response.status = 204
    else
      response.status = 405
    end
  end
end

# Start server
puts "Starting standalone RESTful API server on http://localhost:4567"
puts "Press Ctrl+C to stop the server"

# Handle graceful shutdown
trap('INT') { server.shutdown }
trap('TERM') { server.shutdown }

# Start the server
server.start
