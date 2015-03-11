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
require './models/team_appointment'
require './models/invitation'
require './models/teams_relations'
require './models/team_snapshot'
require 'gravatar-ultimate'
require 'sinatra-websocket'
require 'rest_client'
require 'pony'
require 'bcrypt'
require 'date'
require 'rufus-scheduler'

class App < Sinatra::Base

  register Sinatra::ActiveRecordExtension
  register Sinatra::Namespace
  auth_url = ENV['AUTH_URL'] || 'http://localhost:8000/auth'
  set :show_exceptions, :after_handler
  set :bind, '0.0.0.0'
  set :server, 'thin'
  set :sockets, []
  set :protection, :except => [:json_csrf]
  set :logging, true
  
  I18n.config.enforce_available_locales = true

  include BCrypt

  error ActiveRecord::RecordInvalid do
    status 400
    body env['sinatra.error'].message
  end

  error ActiveRecord::RecordNotFound do
    status 404
    body env['sinatra.error'].message
  end


  def login_required!
    halt 401 if @userid.nil?
  end

  get '/login' do
    content_type 'text/html'
    send_file File.join(settings.public_folder, 'login.html')
  end

  #set notifications to the checked status
  def mark_notification_as_read!
    notification = User.find(@userid).notifications
    @received_msg.each do |notify|
      notification.update(notify["id"], :checked => true);
    end
  end

  get '/' do
    if request.websocket?
      request.websocket do |ws|
        ws.onopen do
          settings.sockets[@userid] = ws
        end
        ws.onmessage do |msg|
          if msg != "keep alive"
            @received_msg = JSON.parse(msg)
            mark_notification_as_read!
          end
        end
        ws.onclose do
          settings.sockets.delete(ws)
        end
      end
    elsif @userid.nil?
      redirect "/login"
    else
      content_type 'text/html'
      send_file File.join(settings.public_folder, 'index.html')
    end

  end

  before do
    unless request.env['HTTP_X_USER'].nil?
      @userid = request.env['HTTP_X_USER'].to_i
    end

    login_required! unless ( ['/users', '/login', '/'].include?(request.path_info) || request.path_info =~ /\/user\/invitation.*/)

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

  get '/teams' do
    Team.all.to_json
  end

  get '/teams/:teamId' do
    Team.find(params[:teamId]).to_json
  end

  get '/teams/:teamId/snapshot' do
   team = Team.find(params[:teamId])
   team.team_snapshots.all.to_json
  end

  post '/teams' do
    team = Team.create!(@body)
    snapshot = TeamSnapshot.create!({:event_type => "create"})
    team.team_snapshots << snapshot
  end

  def get_all_users(team_id)
    result = []

    team = Team.find(team_id)
    result = result | team.users
    member_teams = TeamsRelation.where(:parent_team_id => team_id).pluck(:team_id)
    member_teams.each do |id|
      result = result | get_all_users(id)
    end

    result
  end

  post '/teams/:teamId/delete' do
    Team.delete(params[:teamId])
    200
  end

  #create team with initial users
  post '/teams/users' do
    team = Team.create!(@body["team"])
    snapshot = TeamSnapshot.create!({:event_type => "create"})
    team.team_snapshots << snapshot
    from_user = User.find(@userid)
    from_user.dashboard_records.create!(:content => "You have created a new team : " + team.name, :from_user_id => from_user.id)

    @body["user"].each do |userId|
      user = User.find(userId)
      team.users << user

      snapshot = TeamSnapshot.create!({:event_type => "add_user", :member_user_id => user.id})
      team.team_snapshots << snapshot

      unless userId.equal?(from_user.id)
        user.dashboard_records.create!(:content => from_user.realname + " has added you to team : " + team.name, :from_user_id => from_user.id)
        notification = user.notifications.create!(:content => from_user.realname + " has added you to team : " + team.name, :from_user_id => from_user.id)
        notify = notification.to_json(:except => [:user_id])
        unless settings.sockets[user.id].nil?
          EM.next_tick { settings.sockets[user.id].send(notify) }
        end
      end
    end
    team.to_json
  end

  #get all users in a team
  get '/teams/:teamId/users' do
    # Team.find(params[:teamId]).users.to_json
    get_all_users(params[:teamId]).to_json
  end

  #get all members in a team
  get '/teams/:teamId/members' do

    teams = []
    member_teams = TeamsRelation.where(parent_team_id: params[:teamId]).pluck(:team_id)
    member_teams.each do |team_id|
      teams << Team.find(team_id)
    end

    result = {:users => Team.find(params[:teamId]).users, :teams => teams }
    result.to_json
  end

  post '/teams/:parentTeamId/teams/:teamId' do
    TeamsRelation.create!(:parent_team_id => params[:parentTeamId], :team_id => params[:teamId])
    parent_team = Team.find(params[:parentTeamId])
    snapshot = TeamSnapshot.create!({:event_type => "add team", :member_team_id => params[:teamId]})
    parent_team.team_snapshots << snapshot
  end

  # add a user to a team
  post '/teams/:teamId/users/:userId' do
    team = Team.find(params[:teamId])
    user = User.find(params[:userId])
    team.users << user

    snapshot = TeamSnapshot.create!({:event_type => "add_user", :member_user_id => user.id})
    team.team_snapshots << snapshot
    200
  end

  #add multiple user to a team
  post '/teams/:teamId/users' do
    team = Team.find(params[:teamId])
    @body.each do |userId|
      user = User.find(userId)
      team.users << user

      snapshot = TeamSnapshot.create!({:event_type => "add_user", :member_user_id => user.id})
      team.team_snapshots << snapshot
    end
    200
  end

  #add multiple users and teams to a team
  post '/teams/:teamId/members' do

    teams = @body["teams"]
    users = @body["users"]

    team = Team.find(params[:teamId])

    # add all direct users
    unless users.nil?
      users.each do |userId|
        user = User.find(userId)
        team.users << user

        snapshot = TeamSnapshot.create!({:event_type => "add_user", :member_user_id => userId})
        team.team_snapshots << snapshot
      end
    end

    # add all teams as whole
    unless teams.nil?
      teams.each do |team_id|
        TeamsRelation.create!(:parent_team_id => params[:teamId], :team_id => team_id)
        snapshot = TeamSnapshot.create!({:event_type => "add_team", :member_team_id => team_id})
        team.team_snapshots << snapshot
      end
    end

    200
  end

  #remove a user from team( or a user leaves a team)
  post '/teams/:teamId/users/:userId/remove' do
    team = Team.find(params[:teamId])
    team.users.delete(params[:userId])

    snapshot = TeamSnapshot.create!({:event_type => "remove_user", :member_user_id => params[:userId]})
    team.team_snapshots << snapshot

    user = User.find(params[:userId])
    user.dashboard_records.create!(:content => "You have left team : " + team.name, :from_user_id => params[:userId])

    team.users.each do |member|
      member.dashboard_records.create!(:content => user.realname + " has left team : " + team.name, :from_user_id => params[:userId])
      notification = member.notifications.create!(:content => user.realname + " has left team : " + team.name, :from_user_id => params[:userId])
      notify = notification.to_json(:except => [:user_id])
      unless settings.sockets[member.id].nil?
        EM.next_tick { settings.sockets[member.id].send(notify) }
      end
    end

    200
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

  get '/loggedOnUser' do
    if @userid.nil?
      404
    else
      User.find(@userid).to_json(:except => [:encrypted_password])
    end
  end

  get '/profile' do
    profile = {}
    profile["user"] = User.find(@userid)

  end


  # Calculate the day difference of two dates(date_1 - date_2)
  def day_diff(date_1, date_2)
    return date_1.mjd - date_2.mjd
  end

  # Calculate the month difference of two dates(date_1 - date_2)
  def month_diff(date_1, date_2)
    (date1.year * 12 + date_1.month) - (date_2.year * 12 + date_2.month)
  end

  # Calculate the week difference of two dates(date_1 - date_2)
  def week_diff(date_1, date_2)
    day_diff = day_diff(date_1, date_2)
    if date_1.wday < date_2.wday
      return day_diff / 7 + 1
    else 
      return day_diff / 7
    end
  end

  # Return the number of week day of a date in is month
  # E.g: 2015/1/1 is the first Thursday of January, then this method will return 1
  def week_day_of_month(date) 
    day = date.day
    result = 1
    while day - 7 >= 0 do
      result = result + 1
      day -= 7
    end
    return result
  end

  # Calculate the year difference of two dates(date_1 - date_2)
  def year_diff(date_1, date_2)
    date_1.year - date_2.year
  end

  # Return the fisrt copy of repeated event which will happen after $datetime
  # If there's no such copy, return nil 
  def first_occur_repeated_event_after(event, datetime)
    nil
  end

  # Check whether the events will happen on certain date
  # True, than return the repeated number
  # Otherwise, return 0
  def get_repeated_number(event, date)
    from_date = event.from_time.to_date 

    if !event.repeated 
      date == from_date
    else
      # When the event is repeated
      if date < from_date
        return 0
      elsif date == from_date
        return 1
      end 

      # 1. The date should not exceed the end date of the repeated event
      # If event's event type is to end on certain date
      if event.repeated_end_type == 'Date'
        if event.repeated_end_date < date
          return 0
        end
      end 

      # Days, weeks, months or years after the repeat event's start datetime
      range_after = 0

      # 2. The date should match the repeated type's corresponding date
      daysInWeek = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
      case event.repeated_type
      when "Daily"
        range_after = day_diff(date, from_date)
      when "Weekly"
        # If the week day's of date is not within the repeated setting, return false
        puts daysInWeek
        puts date.wday
        puts event.repeated_on.index(daysInWeek[date.wday])
        if event.repeated_on.index(daysInWeek[date.wday]).nil?
          return 0
        end
        range_after = week_diff(date, from_date)
      when "Monthly"
        if event.repeated_by == 'Month' 
          # When monthly repeated by day of month
          # If the day of month is not equal, return false
          if date.day != from_date.day
            return 0
          end
        elsif event.repeated_by == 'Week' # E.g: both are the second Monday
          # When monthly repeated by day of month
          # If the day of week is not equal, return false
          if !(date.wday == from_date.wday && week_day_of_month(date) == week_day_of_month(from_date))
            return 0
          end
        end
        range_after = month_diff(date, from_date)
      when "Yearly"
        # If not the same day of years, return false
        if !(date.month == from_date.month && date.day == from_date.day)
          return 0
        end
        range_after = year_diff(date, from_date)
      end

      # 3. The date should match the repeated frequency
      # If the date won't match the repeat frequency
      if range_after % event.repeated_frequency != 0
        return 0
      end

      # The repeated number of the repeated event
      repeated_number = range_after / event.repeated_frequency + 1

      # 4. The repeated number should not exceed the setted repeated times 
      # If repeat event will end after certain times
      if event.repeated_end_type == 'Occurence'
        if repeated_number > event.repeated_times
          return 0
        end
      end

      repeated_number
    end
  end

  get '/events' do
    today = Date.today

    user = User.find(@userid)

    all_events = Array.new
    all_events.concat user.events

    user.teams.each { |t|
      all_events.concat t.events
    }

    repeated_events_on_today = Array.new
    today_or_after_events = Array.new
    old_events = Array.new

    all_events.each { |e|
      e.repeated_number = 1

      repeated_number = get_repeated_number(e, today)
      if e.repeated && e.from_time.to_date != today && repeated_number > 0
        day_diff = day_diff(today, e.from_time.to_date)
        new_event = Marshal::load(Marshal.dump(e))
        new_event.from_time = e.from_time + day_diff.days
        new_event.to_time = e.to_time + day_diff.days
        new_event.repeated_number = repeated_number
        today_or_after_events.push(new_event)
        today_or_after_events.push(e)
      elsif e.from_time.to_date >= today
        today_or_after_events.push(e)
      elsif e.from_time.to_date < today
        old_events.push(e)
      end
    }

    result = Array.new
    if today_or_after_events.length >= 5
      result.concat today_or_after_events.sort!{ |a,b| a.from_time <=> b.from_time }.first(5)
    else
      result.concat old_events.sort!{ |a,b| a.from_time <=> b.from_time }.last(5 - today_or_after_events.length)
      result.concat today_or_after_events
    end
    result.to_json(json: Event, methods: [:repeated_number], include: {participants: {only: :id}, team_participants: {only: :id}})
  end

  get '/events/after/:from_time' do
    from = DateTime.parse(params[:from_time])

    events = Array.new
    events.concat User.find(@userid).events.where("from_time > ?", from)

    User.find(@userid).teams.each { |t|
      events.concat t.events.where("from_time > ?", from)
    }

    events.sort!{ |a,b| a.from_time <=> b.from_time }.first(5).to_json(include: {participants: {only: :id}, team_participants: {only: :id}})
  end

  get '/events/before/:from_time' do
    from = DateTime.parse(params[:from_time])

    events = Array.new
    events.concat User.find(@userid).events.where("from_time < ?", from)

    User.find(@userid).teams.each { |t|
      events.concat t.events.where("from_time < ?", from)
    }

    events.sort!{ |a,b| a.from_time <=> b.from_time }.first(5).to_json(include: {participants: {only: :id}, team_participants: {only: :id}})
  end

  get '/events/:eventId' do
      event = Event.find(params[:eventId])
      event.to_json(include: {participants: {only: :id}, team_participants: {only: :id}})
  end

  post '/events' do
    uid = @userid
    event = Event.new(@body.except('participants'))

    notified_users = Array.new
    
    @body['participants']['teams'].each { |p|
      team = Team.find(p)
      event.team_participants << team
      team.users.each { |u|
        if !notified_users.include? u.id 
          notified_users << u.id
        end
      }
    }

    @body['participants']['users'].each { |p|
      user = User.find(p)
      if !notified_users.include? user.id
        notified_users << user.id
        event.participants << user
      end
    }
    
    # Whether the event creator is also a participant by default?
    user_self = User.find(uid)
    if !notified_users.include? uid 
      event.participants << user_self
      notified_users << uid
    end
    event.creator_id = uid

    event.save!

    notified_users.each { |p|
      user = User.find(p)

      message = ''
      if event.creator_id == p
        message = 'You have created an event '
      else
        message = 'Invited you to the event '
      end
      user.dashboard_records.create!({
        content: message, 
        from_user_id: uid,
        has_link: true,
        link_url: '#/calendar/' + event.id.to_s,
        link_title: event.title})

      notification = user.notifications.create!({content: message + event.title, from_user_id: uid})
      
      notify = notification.to_json(:except => [:user_id])
      socket_id = p
      unless settings.sockets[socket_id].nil?
        EM.next_tick { settings.sockets[socket_id].send(notify) }
      end
    }
    
    event.to_json(include: {participants: {only: :id}, team_participants: {only: :id}})
  end

  delete '/events/:eventId' do
    event = Event.find(params[:eventId])
    if @userid == event.creator_id
      uid = @userid

      event.participants.each { |p|
        user = User.find(p.id)
        
        content = ''
        if event.creator_id == p.id
          content = 'You have canceled the event ' + event.title
        else
          content = 'Has canceled the event ' + event.title
        end

        user.dashboard_records.create!({content: content, from_user_id: uid})
        notification = user.notifications.create!({content: content, from_user_id: uid})
        notify = notification.to_json(:except => uid)
        socket_id = p.id
        unless settings.sockets[socket_id].nil?
          EM.next_tick { settings.sockets[socket_id].send(notify) }
        end
      }
      
      event.destroy
      200
    else
      403
    end
  end

  get '/users' do
    User.all.to_json(except: [:encrypted_password, :created_at, :updated_at])
  end

  get '/user/invitation/:inviteId' do
    Invitation.find(params[:inviteId]).to_json
  end

  post '/user/invite' do
    email = @body["email"]
    user = User.find(@userid)
    if @body["initial_team_id"].nil?
      invitation = Invitation.create({:email => email, :from_user_id => @userid, :initial_team_id => -1})
      initial_team = "none"
    else
      invitation = Invitation.create({:email => email, :from_user_id => @userid, :initial_team_id => @body["initial_team_id"]})
      initial_team = Team.find(@body["initial_team_id"]).name
    end

    Pony.mail({
                  :to => email,
                  :subject => user.realname + ' invited you to join teamwork',
                  :headers => {'Content-Type' => 'text/html'},
                  :body => 'Hi there, ' + user.realname + ' invited you to join teamwork' +
                      '<br></br><a href="' + 'http://www.team.work' + '/platform/login?invitation=' + invitation.id.to_s + '">Join now</a>' +
                      '<br><pre>(Please add host record 172.26.142.85 www.team.work)</pre>',
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

    user.dashboard_records.create!(:content => "You have sent an invitation to " + email + " with initial team : " + initial_team, :from_user_id => user.id)
  end

  get '/user/valid_name/:name' do
    if User.where(name: params[:name]).take.nil?
      "valid"
    else
      "inValid"
    end
  end

  get '/user/valid_email/:email' do
    p User.where(email: params[:email])
    if User.where(email: params[:email]).take.nil?
      "valid"
    else
      "inValid"
    end
  end

  post '/users' do
    if @body["initial_team_id"].nil?
      User.create!(@body)
    else
      team = Team.find(@body["initial_team_id"])
      user_obj = {name: @body['name'], realname: @body['realname'], email: @body['email'], password: @body['password']}
      user = User.create!(user_obj)
      team.users << user

      snapshot = TeamSnapshot.create!({:event_type => "create"})
      team.team_snapshots << snapshot
    end
    200
  end

  #change password
  post '/user/password' do
    user = User.find(@userid)
    if user.password == @body["password"]
      new_password = Password.create(@body["newPassword"])
      User.update(@userid, :encrypted_password => new_password)
      user.dashboard_records.create!(:content => "Your password has been successfully changed", :from_user_id => user.id)
      200
    else
      401
    end
  end

  #update user realname
  post '/user/realname/:new_name' do
    User.update(@userid, :realname => params[:new_name])
    200
  end

  # post '/user/:userId' do
  #   User.update(params[:userId], @body)
  # end

  get '/teams_users' do
    teams_users = []
    teams = Team.all
    teams.each do |team|
      member = { :created_at => team.created_at, :updated_at => team.updated_at, :id => team.id, :name => team.name, :users => get_all_users(team.id) }
      teams_users << member
    end

    teams_users.to_json
  end

  #get all team the user attend
  get '/users/:userId/teams' do
    result = []
    teams = User.find(params[:userId]).teams
    teams.each do |team|
      result = result | [Team.find(team.id)]
      parent_teams = TeamsRelation.where(team_id: team.id).pluck(:parent_team_id)
      parent_teams.each do |parent_id|
        result = result | [Team.find(parent_id)]
      end
    end

    result.to_json
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
    content["from_user_id"] = @userid
    users.each do |user|
      record = User.find(user).dashboard_records.create!(content)
    end
    200
  end

  #get all notifications for one user
  get '/users/:userId/notifications' do
    User.find(params[:userId]).notifications.to_json
  end

  #get specified part of notifications for one user
  get '/users/:userId/notifications/:startIndex/:limit' do
    return_obj = {}
    notifications = User.find(params[:userId]).notifications
    if params[:startIndex] == 0
      if notifications.where(checked: false).count < params[:limit]
        return_obj["notifications"] = notifications.limit(params[:limit]).offset(0)
      else
        return_obj["notifications"] = notifications.where(checked: false)
      end
    else
      return_obj["notifications"] = notifications.limit(params[:limit]).offset(params[:startIndex])
    end
    return_obj["total"] = notifications.count
    return_obj.to_json
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
    content["from_user_id"] = @userid

    unless @body["url"].nil?
      content["url"] = @body["url"]
    end

    users.each do |user|
      notification = User.find(user.to_i).notifications.create!(content)
      notify = notification.to_json(:except => [:user_id])
      unless settings.sockets[user.to_i].nil?
        EM.next_tick { settings.sockets[user.to_i].send(notify) }
      end
    end
    200
  end

  # start the server if ruby file executed directly
  run! if app_file == $0
end
