# encoding: utf-8
class App < Sinatra::Base
  auth_url = ENV['AUTH_URL'] || 'http://localhost:8000/auth'

  namespace '/api' do
    post '/genius_coming' do
      if valid_ticket?(@body['ticket'], @body['sign'])
        if user_info = fetch_user_json(@body['ticket'])
          auto_register_user(user_info) unless User.find_by(email: user_info['email'])
          user = User.find_by(email: user_info['email'])
          token = SecureRandom.hex
          RestClient.post auth_url, {token: token, 'userId' => user.id.to_s}.to_json, :content_type => :json
          response.set_cookie("Auth", {
              :value => token,
              :httponly => false,
              :path => '/'
          })
          user.to_json(except: :encrypted_password)
        else
          status 404
        end
      else
        status 406
      end
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
    got = RestClient.post(ENV['GENIUS_QUERY_URL'],
                          {app_id: ENV['GENIUS_APP_ID'], ticket: ticket, sign: app_sign(ticket)},
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

  def valid_ticket?(ticket, got_sign)
    query_to_sign = "#{ticket}-#{ENV['GENIUS_APP_SECRET']}"
    Digest::MD5::hexdigest(query_to_sign) == got_sign
  end

  def app_sign(ticket)
    to_sign = "#{ENV['GENIUS_APP_ID']}-#{ticket}-#{ENV['GENIUS_APP_SECRET']}"
    Digest::MD5::hexdigest(to_sign)
  end
end
