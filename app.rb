require 'sinatra/base'
require 'sinatra/namespace'
require 'sinatra/activerecord'
require './models/plugin.rb'
require './models/team.rb'
require './models/user.rb'
require './models/users_teams.rb'
require './models/dashboard_record'
require './models/notification'
require 'gravatar-ultimate'

class App < Sinatra::Base

  register Sinatra::ActiveRecordExtension
  register Sinatra::Namespace

  set :show_exceptions, :after_handler
  set :bind, '0.0.0.0'

  use Rack::Session::Cookie, :key => 'rack.session',
      :path => '/',
      :secret => 'secret'

  I18n.config.enforce_available_locales = true

  error ActiveRecord::RecordInvalid do
    status 400
    body env['sinatra.error'].message
  end

  get '/' do
    content_type 'text/html'
    send_file File.join(settings.public_folder, 'index.html')
  end

  def login_required!
    halt 401 if session[:user].nil?
  end

  before do
    login_required! unless ["/platform/login", "/platform/signup", "/platform/loggedOnUser", "/"].include?(request.path_info)
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
    get '/gravatar/:userId' do
      user = User.find(params[:userId])
      gravatar = {}
      gravatar["url"] = Gravatar.new(user.email).image_url
      gravatar["username"] = user.realname
      gravatar.to_json
      #todo show local uploaded picture
    end

    get '/gravatar' do
      gravatars = []
      @params.each do |param|
        user = User.find(param[1])
        gravatar = {}
        gravatar["url"] = Gravatar.new(user.email).image_url
        gravatar["username"] = user.realname
        gravatars << gravatar
      end
      gravatars.to_json
      #todo show local uploaded picture
    end

    get '/avatar/uploaded' do
      content_type 'image/png'
      #todo
    end

    post '/avatar' do
      tempfile = params[:file][:tempfile]
      image_data = ""
      tempfile.readlines.each do |line|
        image_data = image_data + line
      end
      #todo save image to db
      # p image_data
      # user = User.find(session[:user][:id])

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
      user = User.where(email: @body["email"], encrypted_password: @body["password"]).first
      if user.nil?
        401
      end

      session[:user] = { :id => user.read_attribute("id") }
      user.to_json
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

    post '/users/:userId/notifications' do
      User.find(params[:userId]).notifications.create!(@body)
    end

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