#!/bin/bash
set -e

# Create database if it doesn't exist (PostgreSQL)
if [[ $DATABASE_URL == postgres://* ]]; then
  echo "Checking PostgreSQL connection..."
  until pg_isready -h ${DATABASE_URL#*@} -q; do
    echo "Waiting for PostgreSQL to become available..."
    sleep 1
  done
fi

# Run database migrations
echo "Running database migrations..."
bundle exec ruby -r './config/database.rb' -e 'Database.migrate'

# Remove any existing server.pid file
rm -f tmp/pids/server.pid

# Execute the command
exec "$@"
