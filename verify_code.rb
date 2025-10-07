require 'sinatra'
require 'redis'
require 'mail'
require 'securerandom'
require 'json'
require 'dotenv'
Dotenv.load

REDIS = Redis.new(url: ENV['REDIS_URL'])

# SMTP Configuration
Mail.defaults do
  delivery_method :smtp, {
    address: ENV['SMTP_HOST'] || 'smtp.gmail.com',
    port: (ENV['SMTP_PORT'] || 587).to_i,
    user_name: ENV['SMTP_USERNAME'],
    password: ENV['SMTP_PASSWORD'],
    authentication: :plain,
    enable_starttls_auto: true
  }
end
# Hàm sinh mã xác thực
def generate_verification_code
  SecureRandom.hex(4) # Tạo mã xác thực ngẫu nhiên, dài 8 ký tự
end

# Hàm gửi email qua SMTP
def send_verification_email(email, code)
  begin
    mail = Mail.new do
      from    'Health Center <' + ENV['SMTP_USERNAME'] + '>'
      #from    ENV['SMTP_USERNAME'] || '
      to      email
      subject 'Your Verification Code From Health Center'
      body    "Your verification code is: #{code}, valid for 5 minutes, please do not share this code with anyone."
    end
    
    mail.deliver!
    puts "Email sent successfully to #{email}"
  rescue => e
    puts "Failed to send email: #{e.message}"
    raise e
  end
end

# Hàm gửi email tùy chỉnh qua SMTP
def send_custom_email(email, content)
  begin
    mail = Mail.new do
      from    'Health Center <' + ENV['SMTP_USERNAME'] + '>'
      to      email
      subject 'Message from Health Center'
      body    content
    end
    
    mail.deliver!
    puts "Custom email sent successfully to #{email}"
  rescue => e
    puts "Failed to send custom email: #{e.message}"
    raise e
  end
end

get '/api/v1/mail/health' do
  status 200
  { message: 'OK' }.to_json
end

# Route nhận yêu cầu HTTP POST để tạo mã xác thực
post '/api/v1/mail/verify_code' do
  #request.body.rewind
  request_body = request.body.read

    if request_body.empty?
      halt 400, "Body is empty"
    end

    data = JSON.parse(request_body)
  email = data['email']

  if email.nil? || email.empty?
    status 400
    return { error: 'Email is required' }.to_json
  end

  verification_code = generate_verification_code

  # Lưu mã xác thực vào Redis với TTL 5 phút
  REDIS.setex("verify_code:#{email}", 5 * 60, verification_code)

  # Gửi mã xác thực qua email
  begin
    send_verification_email(email, verification_code)
    status 200
    { message: "Verification code sent to #{email}" }.to_json
  rescue => e
    # If email sending fails, remove the verification code from Redis
    REDIS.del("verify_code:#{email}")
    status 500
    { error: "Failed to send email: #{e.message}" }.to_json
  end
end


# Route nhận yêu cầu HTTP POST để xác thực mã xác thực
post '/api/v1/mail/validate_code' do
    #request.body.rewind
    request_body = request.body.read

    if request_body.empty?
      halt 400, "Body is empty"
    end

    data = JSON.parse(request_body)
    email = data['email']
    code = data['code']
  
    if email.nil? || email.empty? || code.nil? || code.empty?
      status 400
      return { error: 'Email and code are required' }.to_json
    end
  
    # Lấy mã xác thực từ Redis
    stored_code = REDIS.get("verify_code:#{email}")
  
    if stored_code.nil?
      status 404
      return { error: 'Verification code not found' }.to_json
    end
  
    if stored_code == code
      # Xóa mã xác thực khỏi Redis sau khi xác thực thành công
      REDIS.del("verify_code:#{email}")
      status 200
      { message: 'Verification code is valid' }.to_json
    else
      status 400
      { error: 'Invalid verification code' }.to_json
    end
  end

# Route nhận yêu cầu HTTP POST để gửi email tùy chỉnh
post '/api/v1/mail/send_custom' do
  request_body = request.body.read

  if request_body.empty?
    halt 400, "Body is empty"
  end

  data = JSON.parse(request_body)
  email = data['email']
  content = data['content']

  if email.nil? || email.empty? || content.nil? || content.empty?
    status 400
    return { error: 'Email and content are required' }.to_json
  end

  begin
    send_custom_email(email, content)
    status 200
    { message: "Custom email sent to #{email}" }.to_json
  rescue => e
    status 500
    { error: "Failed to send email: #{e.message}" }.to_json
  end
end

# Cấu hình port và chạy server
set :port, 4567
# cho phep truy cap tu ben ngoai
set :bind, '0.0.0.0'
