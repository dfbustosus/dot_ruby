require 'sinatra/base'
require 'sinatra/json'
require 'sinatra/reloader' if ENV['APP_ENV'] == 'development'
require 'json'
require 'rack/cors'
require 'dotenv'
require 'fileutils'

# Load environment variables
Dotenv.load

# Load database configuration
require_relative 'database'

# Load models
Dir["#{File.dirname(__FILE__)}/../lib/models/*.rb"].each { |file| require file }

# Load controllers
Dir["#{File.dirname(__FILE__)}/../lib/controllers/*.rb"].each { |file| require file }

# Load middleware
Dir["#{File.dirname(__FILE__)}/../lib/middleware/*.rb"].each { |file| require file }

# Create necessary directories
FileUtils.mkdir_p('log') unless Dir.exist?('log')
FileUtils.mkdir_p('tmp/pids') unless Dir.exist?('tmp/pids')

# Application class
class Application < Sinatra::Base
  # Configure CORS
  use Rack::Cors do
    allow do
      origins ENV['CORS_ORIGINS'] || '*'
      resource '*', headers: :any, methods: [:get, :post, :put, :delete, :options]
    end
  end

  # Use custom middleware
  use RequestLogger, log_file: File.open("log/#{ENV['APP_ENV'] || 'development'}.log", 'a')
  
  # Use rate limiting in production
  if ENV['APP_ENV'] == 'production' && ENV['REDIS_URL']
    use RateLimiter, limit: (ENV['RATE_LIMIT'] || 100).to_i
    use Rack::Attack
  end

  # Configure Sinatra
  configure do
    set :bind, ENV['HOST'] || '0.0.0.0'
    set :port, ENV['PORT'] || 4567
    set :show_exceptions, ENV['APP_ENV'] == 'development'
    set :json_encoder, :to_json
    set :sessions, expire_after: 2592000 # 30 days
    set :session_secret, ENV['SESSION_SECRET'] || 'change_me_in_production'
    set :protection, except: [:json_csrf]
    set :public_folder, File.join(File.dirname(__FILE__), '..', 'public')
  end

  # Configure development-specific settings
  configure :development do
    register Sinatra::Reloader
  end

  # Connect to database
  before do
    content_type :json
  end

  # Health check endpoint
  get '/health' do
    json status: 'ok', timestamp: Time.now.utc.iso8601
  end

  # API endpoints
  get '/' do
    json message: 'Welcome to the RESTful API', version: '1.0.0'
  end

  # Items endpoints
  get '/api/items' do
    status, data = ItemsController.index
    status status
    json data
  end

  get '/api/items/:id' do
    status, data = ItemsController.show(params[:id])
    status status
    json data
  end

  post '/api/items' do
    # Parse request body
    request_body = JSON.parse(request.body.read)
    status, data = ItemsController.create(request_body)
    status status
    json data
  rescue JSON::ParserError
    status 400
    json error: 'Invalid JSON'
  end

  put '/api/items/:id' do
    # Parse request body
    request_body = JSON.parse(request.body.read)
    status, data = ItemsController.update(params[:id], request_body)
    status status
    json data
  rescue JSON::ParserError
    status 400
    json error: 'Invalid JSON'
  end

  delete '/api/items/:id' do
    status, data = ItemsController.delete(params[:id])
    status status
    json data if data
  end

  # Error handling
  error 404 do
    json error: 'Not found'
  end

  error 500 do
    json error: 'Internal server error'
  end
end
