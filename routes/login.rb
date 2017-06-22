# encoding: utf-8
class App < Sinatra::Base
  auth_url = ENV['AUTH_URL'] || 'http://localhost:8000/auth'
  namespace '/api' do
    post '/genius_coming' do
      if valid_sign?(@body['ticket'], genius_config['GENIUS_APP_SECRET'], @body['sign'])
        puts 'valid_sign'
        if user_info = fetch_user_json(@body['ticket'])
          puts user_info
          auto_register_user(user_info) unless User.find_by(email: user_info['email'])
          user = User.find_by(email: user_info['email'])
          token = SecureRandom.hex
          RestClient.post auth_url, {token: token, 'userId' => user.id.to_s}.to_json, :content_type => :json
          response.set_cookie("Auth", {
              :value => token,
              :httponly => false,
              :path => '/'
          })
          return user.to_json(except: :encrypted_password)
        end
      end
      status 401
    end

    post '/login' do
      user = User.find_by(email: @body["email"])
      if user.nil?
        status 410
      elsif user.password == @body["password"]
        token = SecureRandom.hex
        RestClient.post auth_url, {'token' => token, 'userId' => user.id.to_s}.to_json, :content_type => :json
        response.set_cookie("Auth", {
                                      :value => token,
                                      :httponly => false,
                                      :path => '/'
                                  })
        user.to_json(:except => :encrypted_password)
      else
        status 401
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

  def fetch_user_json(ticket)
    app_id = genius_config['APP_ID']
    secret = genius_config['GENIUS_APP_SECRET']
    got = RestClient.post(genius_config['FETCH_GENIUS_URL'],
                          {
                              app_id: genius_config['APP_ID'],
                              ticket: ticket,
                              sign: md5_sign(app_id, ticket, secret)},
                          :content_type => :json)
    json = JSON.parse(got.body)
    return unless json && json['status'] && json['status']['code'].to_i == 0
    json['user']
  end

  def auto_register_user(json)
    real_name = json['full_name'] || json['email'].sub('@worksap.co.jp', '')
    user = User.create!(realname: real_name, name: real_name, email: json['email'])
    default_team = Team.find_by_name('Guest')
    default_team.users << user if default_team && default_team.users
    default_team.save!
  end

  def valid_sign?(*params, expected)
    md5_sign(params) == expected
  end

  def md5_sign(*info)
    Digest::MD5::hexdigest(info.join('-'))
  end

  def genius_config
    return @gconf if @gconf
    @gconf = {}
    File.read('.env').each_line do |line|
      key, value = line.split('=').map(&:chomp).map(&:strip)
      @gconf[key] = value
    end
    @gconf
  end
end
