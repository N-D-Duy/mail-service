# Chọn image cơ sở với Ruby
FROM ruby:3.2

# Cài đặt Node.js (nếu cần cho các gem hoặc asset)
# RUN apt-get update -qq && apt-get install -y nodejs

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
