FROM ruby:2.6.10-alpine

# Set environment variables
ENV APP_HOME /app
ENV BUNDLE_PATH /usr/local/bundle
ENV BUNDLE_JOBS 4
ENV BUNDLE_RETRY 3
ENV RACK_ENV production
ENV APP_ENV production

# Install dependencies
RUN apk add --update --no-cache \
    build-base \
    postgresql-dev \
    sqlite-dev \
    tzdata \
    git \
    curl \
    bash \
    less \
    nodejs \
    npm

# Create app directory
WORKDIR $APP_HOME

# Install bundler
RUN gem install bundler -v 1.17.2

# Copy Gemfile and install gems
COPY Gemfile Gemfile.lock* ./
RUN bundle install --jobs $BUNDLE_JOBS --retry $BUNDLE_RETRY --without development test

# Copy application code
COPY . .

# Create necessary directories
RUN mkdir -p log tmp/pids tmp/sockets public/assets db/backups

# Set permissions
RUN chmod +x bin/* start_server.rb

# Expose port
EXPOSE 4567

# Set entrypoint
ENTRYPOINT ["./bin/docker-entrypoint.sh"]

# Start the server
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
