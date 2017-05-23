class App < Sinatra::Base
  namespace '/api' do
    get '/login_callback' do
      if verify_sign(params[:ticket], params[:sign])
        user_info = fetch_user_info_by_ticket(params[:ticket])
        if user_info != nil && user = User.find_by(email: user_info['email'])
          response.set_cookie("Auth", {
              value: SecureRandom.hex,
              httponly: false,
              path: '/'})
          user.to_json(:except => :encrypted_password)
        else
          status 410
        end
        status 406 # BAD REQUEST
      end
    end
  end

  def verify_sign(ticket, sign)
    sign == DIgest::MD5.hexdigest("#{ticket}-#{ENV['MC_CRENDENTIAL']}")
  end


  def auth_sign(ticket)
    Digest::MD5.hexdigest("#{ENV['MC_APP_ID']}-#{ticket}-#{ENV['MC_CREDENTIAL']}")
  end

  def aes_decrypt(data)

  end

  def mc_auth_url
    "http://#{ENV['MC_HOST']}:3000/auth"
  end

  def fetch_user_info_by_ticket(ticket)
    payload = {app_id: ENV['MC_APP_ID'],
               ticket: ticket,
               sign: auth_sign(ticket)}
    result = HTTParty.post(mc_auth_url, payload).parsed_response
    # TODO-impl: verify sign
    if result['status']['code'] == 0
      return result['user']
    end
  end

end
