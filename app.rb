require 'sinatra'
require 'sinatra/json'
require 'sinatra/reloader' if development?
require 'json'
require 'rack/cors'

# Configure CORS
use Rack::Cors do
  allow do
    origins '*'
    resource '*', headers: :any, methods: [:get, :post, :put, :delete, :options]
  end
end

# Configure Sinatra
configure do
  set :bind, '0.0.0.0'
  set :port, ENV['PORT'] || 4567
  set :show_exceptions, development?
  set :json_encoder, :to_json
end

# In-memory data store (replace with a database in production)
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

# Root endpoint
get '/' do
  json message: 'Welcome to the RESTful API'
end

# GET all items
get '/api/items' do
  json ITEMS
end

# GET a specific item
get '/api/items/:id' do
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
    status 500
    json message: "Error: #{e.message}"
  end
end

# PUT/update an existing item
put '/api/items/:id' do
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
  item = find_item(params[:id])
  
  if item
    ITEMS.delete(item)
    status 204
  else
    status 404
    json message: 'Item not found'
  end
end
