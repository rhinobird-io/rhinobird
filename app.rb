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
require './models/invitation'
require 'gravatar-ultimate'
require 'sinatra-websocket'
require 'rest_client'
require 'pony'

class App < Sinatra::Base

  register Sinatra::ActiveRecordExtension
  register Sinatra::Namespace
  auth_url = 'http://localhost:8000/auth'
  set :show_exceptions, :after_handler
  set :bind, '0.0.0.0'
  set :server, 'thin'
  set :sockets, []

  I18n.config.enforce_available_locales = true

  error ActiveRecord::RecordInvalid do
    status 400
    body env['sinatra.error'].message
  end

  def login_required!
    halt 401 if request.env['HTTP_USER'].nil?
  end

  get '/login' do
    content_type 'text/html'
    send_file File.join(settings.public_folder, 'login.html')
  end

  #set notifications to the checked status
  def mark_notification_as_read!
    notification = User.find(request.env['HTTP_USER'].to_i).notifications
    @received_msg.each do |notify|
      notification.update(notify["id"], :checked => true);
    end
  end

  get '/' do
    if request.websocket?
      request.websocket do |ws|
        ws.onopen do
          settings.sockets[request.env['HTTP_USER'].to_i] = ws
        end
        ws.onmessage do |msg|
          @received_msg = JSON.parse(msg)
          mark_notification_as_read!
          # EM.next_tick { ws.send(msg) }
        end
        ws.onclose do
          settings.sockets.delete(ws)
        end
      end
    else
      content_type 'text/html'
      send_file File.join(settings.public_folder, 'index.html')
    end

  end

  before do
    login_required! unless ["/platform/login", "/platform/users", "/login"].include?(request.path_info)
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

  #gravatar related
  get '/gravatars' do
    User.all.map { |u|
      {
          id: u.id,
          url: get_image_url(u.id, u),
          username: u.realname
      }
    }.to_json
  end

  get '/gravatar/:userId' do
    user = User.find(params[:userId])
    gravatar = {}
    gravatar["username"] = user.realname
    gravatar["url"] = get_image_url(params[:userId], user)
    if user.local_avatar.nil?
      gravatar["local"] = false
    else
      gravatar["local"] = true
    end
    gravatar.to_json
  end

  get '/gravatar' do
    gravatars = []
    @params.each do |param|
      user = User.find(param[1])
      gravatar = {}
      gravatar["url"] = get_image_url(param[1], user)
      gravatar["username"] = user.realname
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
      url = "#{request.env['rack.url_scheme']}://#{request.env['HTTP_HOST']}" + "/platform/avatar/" + User.find(user_id).local_avatar.id.to_s
    end

    return url
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
    User.find(request.env['HTTP_USER'].to_i).local_avatar = LocalAvatar.create!(avatar)
  end

  #remove local avatar
  post '/avatar/remove' do
    # @local_avatar = nil
    User.find(request.env['HTTP_USER'].to_i).local_avatar.delete
  end

  get '/teams' do
    Team.all.to_json
  end

  post '/teams' do
    Team.create!(@body)
  end

  post '/teams/:teamId/delete' do
    Team.delete(params[:teamId])
    200
  end

  #create team with initial users
  post '/teams/users' do
    team = Team.create(@body["team"])
    @body["user"].each do |userId|
      user = User.find(userId)
      team.users << user
    end
    team.to_json
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

  #add multiple user to a team
  post '/teams/:teamId/users' do
    team = Team.find(params[:teamId])
    @body.each do |userId|
      user = User.find(userId)
      team.users << user
    end
    200
  end

  #remove a user from team
  post '/teams/:teamId/users/:userId/remove' do
    team = Team.find(params[:teamId])
    team.users.delete(params[:userId])
    200
  end

  post '/login' do
    user = User.find_by(email: @body["email"])
    if user.nil?
      status 410
    elsif user.password == @body["password"]
      token = SecureRandom.hex
      RestClient.post auth_url, { 'token' => token, 'userId' => user.id.to_s }.to_json, :content_type => :json
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

  get '/loggedOnUser' do
    if request.env['HTTP_USER'].nil?
      404
    else
      User.find(request.env['HTTP_USER'].to_i).to_json(:except => [:encrypted_password])
    end
  end

  get '/profile' do
    profile = {}
    profile["user"] = User.find(request.env['HTTP_USER'].to_i)

  end

  get '/users/:userId/events' do
    User.find(params[:userId]).events.order(:from).to_json(include: {participants: {only: :id}})
  end

  post '/events' do
    uid = request.env['HTTP_USER'].to_i
    event = Event.new(@body.except('participants'))
    @body['participants'].each { |p|
      event.participants << User.find(p)
    }
    # Whether the event creator is also a participant by default?
    event.participants << User.find(uid);
    event.save!
    event.to_json(include: {participants: {only: :id}})
  end

  delete '/events/:eventId' do
    event = Event.find(params[:eventId])
    event.destroy
    200
  end

  get '/users' do
    User.all.to_json
  end

  get '/user/invitation/:inviteId' do
    Invitation.find(params[:inviteId]).to_json
  end

  post '/user/invite' do
    email = @body["email"]
    user = User.find(request.env['HTTP_USER'].to_i)
    if @body["initial_team_id"].nil?
      invitation = Invitation.create({:email => email, :from_user_id => request.env['HTTP_USER'].to_i, :initial_team_id => -1})
    else
      invitation = Invitation.create({:email => email, :from_user_id => request.env['HTTP_USER'].to_i, :initial_team_id => @body["initial_team_id"]})
    end

    Pony.mail({
                  :to => email,
                  :subject => user.realname + ' invited you to join teamwork',
                  :headers => {'Content-Type' => 'text/html'},
                  :body => 'Hi there, ' + user.realname + ' invited you to join teamwork' +
                      '<br></br><a href="' + request.base_url + '/platform/login?invitation=' + invitation.id.to_s + '">Join now</a>',
                  :via => :smtp,
                  :via_options => {
                      :address => 'smtp.gmail.com',
                      :port => '25',
                      :user_name => 'teamwork.ate@gmail.com',
                      :password => 'ateshanghai',
                      :authentication => :plain, # :plain, :login, :cram_md5, no auth by default
                      :domain => "localhost.localdomain" # the HELO domain provided by the client to the server
                  }
              })
  end

  post '/users' do
    if @body["initial_team_id"].nil?
      User.create!(@body)
    else
      team = Team.find(@body["initial_team_id"])
      user_obj = {:realname => @body["realname"], :email => @body["email"], :password => @body["password"]}
      user = User.create!(user_obj)
      team.users << user
    end
    200
  end

  #change password
  post '/user/password' do
    user = User.find(request.env['HTTP_USER'].to_i)
    if user.password == @body["password"]
      new_password = Password.create(@body["newPassword"])
      User.update(request.env['HTTP_USER'].to_i, :encrypted_password => new_password)
      200
    else
      401
    end
  end

  # post '/user/:userId' do
  #   User.update(params[:userId], @body)
  # end

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
    content["from_user_id"] = request.env['HTTP_USER'].to_i
    users.each do |user|
      record = User.find(user).dashboard_records.create!(content)
    end
    200
  end

  #get unchecked notifications for one user
  get '/users/:userId/notifications' do
    User.find(params[:userId]).notifications.where({checked: false}).to_json
  end

  #get all notification history for one user
  get '/users/:userId/notifications/history' do
    User.find(params[:userId]).notifications.to_json
  end

  # add a notification to one user
  post '/users/:userId/notifications' do
    notification = User.find(params[:userId]).notifications.create!(@body)
    notify = notification.to_json(:except => [:user_id])
    socket_id = params[:userId].to_i
    unless settings.sockets[socket_id].nil?
      EM.next_tick { settings.sockets[socket_id].send(notify) }
    end
    200
  end

  # add a notification to many users
  post '/users/notifications' do
    users = @body["users"]
    content =@body["content"]
    content["from_user_id"] = request.env['HTTP_USER'].to_i
    users.each do |user|
      notification = User.find(user).notifications.create!(content)
      notify = notification.to_json(:except => [:user_id])
      unless settings.sockets[user].nil?
        EM.next_tick { settings.sockets[user].send(notify) }
      end
    end
    200
  end

  # start the server if ruby file executed directly
  run! if app_file == $0

end
