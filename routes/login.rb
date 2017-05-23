# encoding: utf-8
class App < Sinatra::Base
  auth_url = ENV['AUTH_URL'] || 'http://localhost:8000/auth'
  namespace '/api' do
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
end
