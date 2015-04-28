# encoding: utf-8
require 'gravatar-ultimate'
class App < Sinatra::Base
  namespace '/api' do
    #gravatar related
    get '/gravatars/all' do
      User.all.map { |u|
        {
            id: u.id,
            url: get_image_url(u.id, u),
            name: u.name,
            realname: u.realname,
            email: u.email,
            local: !u.local_avatar.nil?
        }
      }.to_json
    end

    get '/gravatar/:type/:value' do
      if params[:type] == "id"
        user = User.find(params[:value])
      else
        user = User.where(name: params[:value]).take
      end

      gravatar = {}
      gravatar["id"] = user.id
      gravatar["url"] = get_image_url(user.id, user)
      gravatar["name"] = user.name
      gravatar["realname"] = user.realname
      gravatar["email"] = user.email
      gravatar["local"] = !user.local_avatar.nil?
      gravatar.to_json
    end

    #get the array of gravatars with the given list of user id
    get '/gravatars' do
      gravatars = []
      @params.each do |param|
        user = User.find(param[1])
        gravatar = {}
        gravatar["id"] = user.id
        gravatar["url"] = get_image_url(user.id, user)
        gravatar["name"] = user.name
        gravatar["realname"] = user.realname
        gravatar["email"] = user.email
        gravatar["local"] = !user.local_avatar.nil?
        gravatars << gravatar
      end
      gravatars.to_json
    end

    def get_image_url(user_id, user=nil)
      # if @local_avatar.nil?
      #   @local_avatar = @user.local_avatar
      # end
      if user.nil?
        user = User.find(user_id)
      end

      if user.local_avatar.nil?
        url = Gravatar.new(user.email).image_url
      else
        url = "/platform/avatar/" + User.find(user_id).local_avatar.id.to_s
      end

      url
    end

    get '/avatar/:avatarId' do
      avatar = LocalAvatar.find(params[:avatarId])
      if avatar.nil?
        404
      else
        content_type 'image/png'
        image_data = Base64.decode64(avatar["image_data"])
        image_data
      end
    end

    #upload local avatar
    post '/avatar' do
      tempfile = params[:file][:tempfile]
      image_data = ""
      tempfile.readlines.each do |line|
        image_data = image_data + line
      end

      avatar = {:image_data => Base64.encode64(image_data)}
      User.find(@userid).local_avatar = LocalAvatar.create!(avatar)
    end

    #remove local avatar
    post '/avatar/remove' do
      # @local_avatar = nil
      User.find(@userid).local_avatar.delete
    end
  end
end