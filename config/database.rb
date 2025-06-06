require 'sequel'
require 'logger'
require 'dotenv'

Dotenv.load

module Database
  class << self
    attr_reader :db

    def connect
      # Create log directory if it doesn't exist
      FileUtils.mkdir_p('log') unless Dir.exist?('log')
      
      # Setup database connection
      @db = if ENV['DATABASE_URL']
              Sequel.connect(ENV['DATABASE_URL'])
            else
              # Fallback to SQLite if no DATABASE_URL is provided
              Sequel.sqlite('db/development.sqlite3')
            end

      # Configure database logging
      log_level = ENV['LOG_LEVEL'] || 'info'
      log_file = File.open("log/database_#{ENV['APP_ENV'] || 'development'}.log", 'a')
      @db.loggers << Logger.new(log_file)
      @db.loggers << Logger.new($stdout) if ENV['APP_ENV'] == 'development'
      
      # Set SQL log level
      @db.sql_log_level = log_level.to_sym
      
      # Load database extensions
      @db.extension :pagination
      
      # Return the database connection
      @db
    end

    def disconnect
      @db&.disconnect
    end

    def migrate(direction = :up)
      Sequel.extension :migration
      db = connect
      
      if direction == :up
        puts "Running database migrations..."
        Sequel::Migrator.run(db, 'db/migrations')
        puts "Migrations complete!"
      elsif direction == :down
        puts "Rolling back migrations..."
        Sequel::Migrator.run(db, 'db/migrations', target: 0)
        puts "Rollback complete!"
      else
        puts "Unknown migration direction: #{direction}"
      end
    end
  end
end
