# encoding: utf-8
class App < Sinatra::Base
  auth_url = ENV['AUTH_URL'] || 'http://localhost:8000/auth'
  namespace '/api' do
    post '/login' do
      user = auth_user(@body['email'], @body['password'])
      if user.nil?
        status 410
      else
        token = SecureRandom.hex
        RestClient.post auth_url, {'token' => token, 'userId' => user.id.to_s}.to_json, :content_type => :json
        response.set_cookie("Auth", {
                                      :value => token,
                                      :httponly => false,
                                      :path => '/'
                                  })
        user.to_json(:except => :encrypted_password)
      end
    end

    post '/logout' do
      #TODO
    end

    get '/login' do
      if @userid.nil?
        404
      else
        User.find(@userid).to_json(:except => [:encrypted_password])
      end
    end

    post '/signup' do
        user = User.create!(realname: @body['name'], name: @body['uniqueName'], email: "#{@body['email']}@worksap.co.jp", encrypted_password: Password.create(@body['password']))
        Team.find_by_name('Guest').users << user
        user.to_json(:except => :encrypted_password)
    end
  end

  def auth_user(user_name, password)
    conf = genius_config
    got = RestClient.post(conf['LOGIN_PATH'], {
        app_id: conf['APP_ID'],
        user_name: user_name,
        password: password,
        direct_login: true,
        sign: generate_sign(conf['APP_ID'], user_name, password, 'true', conf['SECRET_KEY'])})
    json = JSON.parse(got.body)
    puts json
    # puts json['user_name']
    # puts json['email']
    fetch_or_create_user_by(json) if json['status']['code'].to_i == 0
  end

  def fetch_or_create_user_by(json)
    unless User.find_by(email: json['user']['email'])
      user = User.create!(realname: json['user']['email'].sub('@worksap.co.jp',''), name: json['user']['user_name'], email: json['user']['email'])
      Team.find_by_name('Guest').users << user if Team.find_by_name('Guest').users
    end
    User.find_by(email: json['user']['email'])
  end

  def genius_config
    conf = {}
    File.read('.env').each_line do |line|
      key, value = line.split('=').map(&:chomp).map(&:strip)
      conf[key] = value
    end
    conf
  end

  def generate_sign(*params)
    Digest::MD5::hexdigest(params.map(&:to_s).join('-'))
  end
end
