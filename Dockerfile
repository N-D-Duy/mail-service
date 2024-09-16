# Chọn image cơ sở với Ruby
FROM ruby:3.1.6-alpine

# Cài đặt các công cụ xây dựng và thư viện cần thiết
RUN apk update && apk add --no-cache \
  build-base \
  libpq-dev \
  nodejs \
  npm

# Tạo thư mục làm việc trong container
WORKDIR /app

# Sao chép Gemfile và Gemfile.lock vào thư mục làm việc
COPY Gemfile /app/Gemfile
COPY Gemfile.lock /app/Gemfile.lock

# Cài đặt các gem
RUN bundle install

# Sao chép mã nguồn ứng dụng vào thư mục làm việc
COPY . /app

# Chạy ứng dụng Sinatra khi container khởi động
CMD ["ruby", "verify_code.rb"]
