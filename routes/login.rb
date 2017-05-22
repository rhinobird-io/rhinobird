# encoding: utf-8
class App < Sinatra::Base
  include HTTParty
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

    get '/mc_login_call' do
      if verify_sign(params[:ticket], params[:sign])
        response = self.post('http://mcenter.internal.worksap.com/auth', body: {app_id: 'rhinobird', ticket: params[:ticket], sign: auth_sign(params[:ticket])}).parsed_response
        email = reponse["email_prefix"] + "@worksap.co.jp"
        user = User.find_by(email: email)
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
      else
        status 406
      end
    end

    get 'login_from_member_center' do
      redirect 'http://mcenter.internal.worksap.com/login?app_id=rhinobird'
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

def verify_sign(ticket, sign)
  sign == DIgest::MD5.hexdigest("#{ticket}-#{ENV['RHINOBIRD_CRENDENTIAL']}")
end


def auth_sign(ticket)
  Digest::MD5.hexdigest("rhinobird-#{ticket}-#{ENV['RHINOBIRD_CREDENTIAL']}")
  end
end
