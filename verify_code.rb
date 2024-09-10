require 'sinatra'
require 'redis'
require 'rest-client'
require 'securerandom'
require 'json'
require 'dotenv'
Dotenv.load

# Cấu hình Redis
REDIS = Redis.new(url: ENV['REDIS_URL'])
API_KEY=ENV['MAILGUN_API_KEY']
HOST=ENV['MAILGUN_HOST']
# Hàm sinh mã xác thực
def generate_verification_code
  SecureRandom.hex(4) # Tạo mã xác thực ngẫu nhiên, dài 8 ký tự
end


# Hàm gửi email qua Mailgun
def send_verification_email(email, code)
  RestClient.post "https://api:#{API_KEY}@api.mailgun.net/v3/#{HOST}/messages",
                  from: "Duy Nguyen <mailgun@mg.duynguyendev.xyz>",
                  to: email,
                  subject: "Your Verification Code",
                  text: "Your verification code is: #{code}"
end

# Route nhận yêu cầu HTTP POST để tạo mã xác thực
post '/verify_code' do
  request.body.rewind
  data = JSON.parse(request.body.read)
  email = data['email']

  if email.nil? || email.empty?
    status 400
    return { error: 'Email is required' }.to_json
  end

  verification_code = generate_verification_code

  # Lưu mã xác thực vào Redis với TTL 5 phút
  REDIS.setex("verify_code:#{email}", 5 * 60, verification_code)

  # Gửi mã xác thực qua email
  send_verification_email(email, verification_code)

  status 200
  { message: "Verification code sent to #{email}" }.to_json
end


# Route nhận yêu cầu HTTP POST để xác thực mã xác thực
post '/validate_code' do
    request.body.rewind
    data = JSON.parse(request.body.read)
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

# Cấu hình port và chạy server
set :port, 4567
