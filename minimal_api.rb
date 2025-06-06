require 'sinatra'
require 'json'

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

# Set content type for all responses
before do
  content_type :json
end

# Root endpoint
get '/' do
  { message: 'Welcome to the RESTful API', version: '1.0.0' }.to_json
end

# GET all items
get '/api/items' do
  ITEMS.to_json
end

# GET a specific item
get '/api/items/:id' do
  item = find_item(params[:id])
  if item
    item.to_json
  else
    status 404
    { message: 'Item not found' }.to_json
  end
end

# POST a new item
post '/api/items' do
  begin
    # Parse request body
    request_body = JSON.parse(request.body.read)
    
    # Create new item
    new_item = {
      id: next_id,
      name: request_body['name'],
      description: request_body['description']
    }
    
    # Add to collection
    ITEMS << new_item
    
    # Return the created item
    status 201
    new_item.to_json
  rescue JSON::ParserError
    status 400
    { message: 'Invalid JSON' }.to_json
  rescue => e
    status 500
    { message: "Error: #{e.message}" }.to_json
  end
end

# PUT/update an existing item
put '/api/items/:id' do
  item = find_item(params[:id])
  
  if item
    begin
      # Parse request body
      request_body = JSON.parse(request.body.read)
      
      # Update item
      item[:name] = request_body['name'] if request_body['name']
      item[:description] = request_body['description'] if request_body['description']
      
      # Return updated item
      item.to_json
    rescue JSON::ParserError
      status 400
      { message: 'Invalid JSON' }.to_json
    rescue => e
      status 500
      { message: "Error: #{e.message}" }.to_json
    end
  else
    status 404
    { message: 'Item not found' }.to_json
  end
end

# DELETE an item
delete '/api/items/:id' do
  item = find_item(params[:id])
  
  if item
    ITEMS.delete(item)
    status 204
    ''
  else
    status 404
    { message: 'Item not found' }.to_json
  end
end
