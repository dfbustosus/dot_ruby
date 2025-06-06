# Ruby RESTful API

A simple RESTful API built with Ruby 2.6.10 and Sinatra.

## Requirements

- Ruby 2.6.10
- Bundler

## Installation

```bash
# Install dependencies
bundle install
```

## Starting the Server

```bash
# Method 1: Using the start script
ruby start_server.rb

# Method 2: Using rackup directly
bundle exec rackup -p 4567 -o 0.0.0.0
```

The API will be available at http://localhost:4567

## API Endpoints

### GET /
- Returns a welcome message
- Response: `{"message": "Welcome to the RESTful API"}`

### GET /api/items
- Returns all items
- Response: Array of item objects

### GET /api/items/:id
- Returns a specific item by ID
- Response: Item object or 404 error

### POST /api/items
- Creates a new item
- Request body: `{"name": "Item name", "description": "Item description"}`
- Response: Created item with status 201

### PUT /api/items/:id
- Updates an existing item
- Request body: `{"name": "Updated name", "description": "Updated description"}`
- Response: Updated item or 404 error

### DELETE /api/items/:id
- Deletes an item
- Response: Status 204 (No Content) or 404 error

## Example Usage

```bash
# Get all items
curl http://localhost:4567/api/items

# Create a new item
curl -X POST http://localhost:4567/api/items \
  -H "Content-Type: application/json" \
  -d '{"name": "New Item", "description": "A new item description"}'

# Update an item
curl -X PUT http://localhost:4567/api/items/1 \
  -H "Content-Type: application/json" \
  -d '{"name": "Updated Item"}'

# Delete an item
curl -X DELETE http://localhost:4567/api/items/1
```