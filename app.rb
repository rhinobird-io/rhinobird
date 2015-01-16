require 'sinatra/base'
require 'sinatra/namespace'
require 'sinatra/activerecord'
require './models/plugin.rb'
require './models/team.rb'
require './models/user.rb'
require './models/users_teams.rb'
require './models/dashboard_record'
require './models/notification'
require './models/local_avatar'
require './models/event'
require './models/appointment'
require 'gravatar-ultimate'
require 'sinatra-websocket'
require "bcrypt"

class App < Sinatra::Base

  register Sinatra::ActiveRecordExtension
  register Sinatra::Namespace

  include BCrypt

  set :show_exceptions, :after_handler
  set :bind, '0.0.0.0'
  set :server, 'thin'
  set :sockets, []

  use Rack::Session::Cookie, :key => 'rack.session',
      :path => '/',
      :secret => 'secret'

  I18n.config.enforce_available_locales = true

  error ActiveRecord::RecordInvalid do
    status 400
    body env['sinatra.error'].message
  end

  get '/' do
    if request.websocket?
      request.websocket do |ws|
        ws.onopen do
          ws.send("Hello World!")
          settings.sockets[session[:user][:id]] = ws
        end
        ws.onmessage do |msg|
          EM.next_tick { ws.send(msg) }
        end
        ws.onclose do
          warn("websocket closed")
          settings.sockets.delete(ws)
        end
      end
    else
      content_type 'text/html'
      send_file File.join(settings.public_folder, 'index.html')
    end

  end

  def login_required!
    halt 401 if session[:user].nil?
  end

  before do
    login_required! unless ["/platform/login", "/platform/users", "/platform/loggedOnUser", "/"].include?(request.path_info)
    content_type 'application/json'
    if request.media_type == 'application/json'
      body = request.body.read
      unless body.empty?
        @body = JSON.parse(body)
      end
    end
  end

  namespace '/home' do
    get '*' do
      content_type 'text/html'
      send_file File.join(settings.public_folder, 'index.html')
    end
  end

  namespace '/developer' do

    get '/?' do
      content_type 'text/html'
      send_file File.join(settings.public_folder, 'developer/index.html')
    end

    post '/upload' do
      plugin = Plugin.load_from_zip(params['file'][:tempfile])
      plugin.save!

      # Plugin start run a new process and we need to kill it manually.
      # To avoid development trouble, disable it currently
      # When we want to test the running plugin, uncomment it
      p "start plugin"
      plugin.start
      p "started plugin"
      plugin.to_json
    end

    get '/plugins' do
      Plugin.all.to_json
    end

    post '/plugins' do
      Plugin.create!(@body)
    end
  end

  namespace '/platform' do

    #gravatar related
    get '/gravatars' do
      User.all.map { |u|
        {
            id: u.id,
            url: Gravatar.new(u.email).image_url,
            username: u.realname
        }
      }.to_json
    end

    get '/gravatar/:userId' do
      @user_id = params[:userId]
      @user = User.find(params[:userId])
      gravatar = {}
      gravatar["username"] = @user.realname
      gravatar["url"] = get_image_url
      gravatar.to_json
    end

    get '/gravatar' do
      gravatars = []
      @params.each do |param|
        @user = User.find(param[1])
        @user_id = param[1]
        gravatar = {}
        gravatar["url"] = get_image_url
        gravatar["username"] = @user.realname
        gravatars << gravatar
      end
      gravatars.to_json
    end

    def get_image_url
      if @local_avatar.nil?
        @local_avatar = @user.local_avatar
      end

      if @local_avatar.nil?
        url = Gravatar.new(@user.email).image_url
      else
        url = "#{request.env['rack.url_scheme']}://#{request.env['HTTP_HOST']}" + "/platform/avatar/" + @user_id
      end

      return url
    end

    get '/avatar/:userId' do
      if @local_avatar.nil?
        @local_avatar = User.find(params[:userId]).local_avatar
      end
      if @local_avatar.nil?
        404
      else
        content_type 'image/png'
        @local_avatar["image_data"]
      end
    end

    post '/avatar' do
      tempfile = params[:file][:tempfile]
      image_data = ""
      tempfile.readlines.each do |line|
        image_data = image_data + line
      end

      avatar = {:image_data => image_data}
      User.find(session[:user][:id]).local_avatar = LocalAvatar.create!(avatar)
    end

    get '/teams' do
      Team.all.to_json
    end

    post '/teams' do
      Team.create!(@body)
    end

    #get all users in a team
    get '/teams/:teamId/users' do
      Team.find(params[:teamId]).users.to_json
    end

    # add a user to a team
    post '/teams/:teamId/users/:userId' do
      team = Team.find(params[:teamId])
      user = User.find(params[:userId])
      team.users << user
      200
    end

    post '/teams/:teamId/users' do
      team = Team.find(params[:teamId])
      @body.each do |userId|
        user = User.find(userId)
        team.users << user
      end
      200
    end

    post '/login' do
      session[:user] = nil
      password = Password.create(@body["password"]).first
      user = User.find_by(email: @body["email"])
      if user.nil?
        status 410
      elsif user.password == @body["password"]
        session[:user] = { :id => user.id }
        user.to_json(:except => :encrypted_password)
      else
        status 401
      end
    end

    post '/logout' do
      session[:user] = nil
    end

    get '/loggedOnUser' do
      if session[:user].nil?
        404
      else
        User.find(session[:user][:id]).to_json
      end
    end

    get '/profile' do
      profile = {}
      profile["user"] = User.find(session[:user][:id])

    end

    get '/users/:userId/events' do
      User.find(params[:userId]).events.order(:from).to_json(include: { participants: {only: :id}})
    end

    post '/events' do
      uid = session[:user][:id]
      event = Event.new(@body.except('participants'))
      @body['participants'].each { |p|
        event.participants << User.find(p)
      }
      event.save!
      200
    end

    get '/users' do
      User.all.to_json
    end

    post '/users' do
      User.create!(@body)
    end

    post '/user/:userId' do
      User.update(params[:userId], @body)
    end

    get '/teams_users' do
      Team.all.to_json(include: [:users]);
    end

    #get all team the user attend
    get '/users/:userId/teams' do
      User.find(params[:userId]).teams.to_json
    end

    get '/users/:userId/dashboard_records' do
      User.find(params[:userId]).dashboard_records.to_json
    end

    post '/users/:userId/dashboard_records' do
      User.find(params[:userId]).dashboard_records.create!(@body)
    end

    post '/users/dashboard_records' do
      users = @body["users"]
      content =@body["content"]
      content["from_user_id"] = session[:user][:id]
      users.each do |user|
        record = User.find(user).dashboard_records.create!(content)
      end
      200
    end

    get '/users/:userId/notifications' do
      User.find(params[:userId]).notifications.to_json
    end

    # add a notification to one user
    post '/users/:userId/notifications' do
      User.find(params[:userId]).notifications.create!(@body)
      content = [@body].to_json
      socket_id = params[:userId].to_i
      unless settings.sockets[socket_id].nil?
        EM.next_tick { settings.sockets[socket_id].send(content) }
      end
    end

    # add a notification to many users
    post '/users/notifications' do
      users = @body["users"]
      content =@body["content"]
      content["from_user_id"] = session[:user][:id]
      users.each do |user|
        record = User.find(user).notifications.create!(content)
      end
      200
    end

    # start the server if ruby file executed directly
    run! if app_file == $0
  end

end
