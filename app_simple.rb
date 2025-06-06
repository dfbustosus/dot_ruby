require 'sinatra'
require 'sinatra/json'
require 'json'
require 'logger'

# Configure logger
log_dir = File.join(File.dirname(__FILE__), 'log')
Dir.mkdir(log_dir) unless File.exist?(log_dir)
logger = Logger.new(File.join(log_dir, 'app.log'))
logger.level = Logger::INFO

# In-memory data store
ITEMS = [
  { id: 1, name: 'Item 1', description: 'Description for item 1' },
  { id: 2, name: 'Item 2', description: 'Description for item 2' }
]

# Configure Sinatra
configure do
  set :bind, '0.0.0.0'
  set :port, ENV['PORT'] || 4567
  set :show_exceptions, development?
  set :json_encoder, :to_json
  set :logging, true
  set :logger, logger
end

# Helper method to find an item by ID
def find_item(id)
  ITEMS.find { |item| item[:id] == id.to_i }
end

# Helper method to generate a new ID
def next_id
  ITEMS.map { |item| item[:id] }.max + 1 rescue 1
end

# Root endpoint
get '/' do
  json message: 'Welcome to the RESTful API', version: '1.0.0'
end

# Health check endpoint
get '/health' do
  json status: 'ok', timestamp: Time.now.utc.iso8601
end

# GET all items
get '/api/items' do
  logger.info "GET request to /api/items"
  json ITEMS
end

# GET a specific item
get '/api/items/:id' do
  logger.info "GET request to /api/items/#{params[:id]}"
  item = find_item(params[:id])
  if item
    json item
  else
    status 404
    json message: 'Item not found'
  end
end

# POST a new item
post '/api/items' do
  logger.info "POST request to /api/items"
  begin
    # Parse request body
    request_body = JSON.parse(request.body.read, symbolize_names: true)
    
    # Create new item
    new_item = {
      id: next_id,
      name: request_body[:name],
      description: request_body[:description]
    }
    
    # Add to collection
    ITEMS << new_item
    
    # Return the created item
    status 201
    json new_item
  rescue JSON::ParserError
    status 400
    json message: 'Invalid JSON'
  rescue => e
    logger.error "Error creating item: #{e.message}"
    status 500
    json message: "Error: #{e.message}"
  end
end

# PUT/update an existing item
put '/api/items/:id' do
  logger.info "PUT request to /api/items/#{params[:id]}"
  item = find_item(params[:id])
  
  if item
    begin
      # Parse request body
      request_body = JSON.parse(request.body.read, symbolize_names: true)
      
      # Update item
      item[:name] = request_body[:name] if request_body[:name]
      item[:description] = request_body[:description] if request_body[:description]
      
      # Return updated item
      json item
    rescue JSON::ParserError
      status 400
      json message: 'Invalid JSON'
    rescue => e
      logger.error "Error updating item: #{e.message}"
      status 500
      json message: "Error: #{e.message}"
    end
  else
    status 404
    json message: 'Item not found'
  end
end

# DELETE an item
delete '/api/items/:id' do
  logger.info "DELETE request to /api/items/#{params[:id]}"
  item = find_item(params[:id])
  
  if item
    ITEMS.delete(item)
    status 204
  else
    status 404
    json message: 'Item not found'
  end
end

# Error handling
error do
  logger.error "Error: #{env['sinatra.error'].message}"
  status 500
  json error: env['sinatra.error'].message
end
