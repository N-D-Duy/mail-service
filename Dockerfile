# Simple Ruby application
FROM ruby:3.2

# Set working directory
WORKDIR /app

# Copy and install gems
COPY Gemfile* ./
RUN bundle install

# Copy application
COPY . .

# Expose port
EXPOSE 4567

# Run application
CMD ["ruby", "verify_code.rb"]
