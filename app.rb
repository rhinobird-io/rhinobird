require 'sinatra/base'
require 'sinatra/activerecord'
require 'sinatra/namespace'
require 'sinatra/config_file'
require 'rest_client'
require 'pony'
require 'bcrypt'
require 'date'
require 'rufus-scheduler'
require 'faye/websocket'
require 'resque'
require 'mail'
require 'sinatra/redis'
require 'sinatra/config_file'
require 'json'
require 'erb'
require 'week_of_month'

Faye::WebSocket.load_adapter('thin')

class EventToComeEmailContent
  attr_reader :user, :event, :hostname
  def initialize(user, event, hostname)
    @user = user
    @event = event
    @hostname = hostname
  end

  def get_binding
    binding
  end
end

def send_event_notifications(e, dashboard_message, dashboard_link, notification_message)
  participants = e.participants
  team_participants = e.team_participants

  users = Array.new

  user_ids = {}
  participants.each { |p|
    users << p
    user_ids[p.id] = true
  }

  team_participants.each { |tp|
    team = Team.find(tp.id)
    team_users = team.get_all_users
    team_users.each { |u|
      unless user_ids[u.id]
        users.push(u)
        user_ids[u.id] = true
      end
    }
  }

  users.each { |u|
    u.dashboard_records.create!(
        {
            content: dashboard_message,
            from_user_id: u.id,
            has_link: true,
            link_url: dashboard_link,
            link_title: e.title,
            link_param: e.to_json(methods: [:repeated_number], only: [:id]),
        }
    )

    notification = u.notifications.create!({content: notification_message,
                                            from_user_id: u.id,
                                            url: "/platform/calendar/events/#{e.id}/#{e.repeated_number}"})

    notify = notification.to_json(:except => [:user_id])

    controller = EventToComeEmailContent.new(u, e, settings.hostname)
    notify(
        u,
        notify,
        "[RhinoBird] Your event #{e.title} will start in half an hour.",
        ERB.new(File.read('./views/email/event_to_come.erb')).result(controller.get_binding))
  }
end

class App < Sinatra::Base
  register Sinatra::ConfigFile

  config_file './config/platform.yml'

  configure :production do
    helpers do
      def target_email(user)
        user[:email]
      end
    end

    redis_url = ENV['REDISCLOUD_URL'] || ENV['OPENREDIS_URL'] || ENV['REDISGREEN_URL'] || ENV['REDISTOGO_URL'] || 'redis://localhost:6379'
    uri = URI.parse(redis_url)
    Resque.redis = Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)
    Resque.redis.namespace = 'resque:rhinobird'
    set :redis, redis_url
  end

  configure :development do
    helpers do
      def target_email(user)
        'li_ju@worksap.co.jp'
      end
    end
    redis_url = 'redis://localhost:6379'
    uri = URI.parse(redis_url)
    Resque.redis = Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)
    Resque.redis.namespace = 'resque:rhinobird'
    set :redis, redis_url
  end

  unless ENV['DISABLE_RUFUS'] == 'TRUE'
    scheduler = Rufus::Scheduler.new

    # Check events that are not full day.
    scheduler.every '30s' do
      puts 'Scheduler'
      now = DateTime.now
      half_an_hour = 30.minute
      half_an_hour_later = now + half_an_hour

      events = Event.where('from_time >= ? and from_time <= ? and full_day = ? and repeated = ? and status <> ?', now, half_an_hour_later, false, false, Event.statuses[:trashed])
      repeated_events = Event.where('repeated = ? and status <> ?', true, Event.statuses[:trashed])

      repeated_events.each { |e|
        repeated_number = e.get_repeated_number(Date.today)
        re = e.get_event_by_repeated_number(repeated_number.to_i)
        if !re.nil? && re.from_time.to_datetime >= now && re.from_time.to_datetime <= half_an_hour_later
          events.push(re)
        end
      }

      count = 0
      events.each { |e|
        #puts e.from_time.to_datetime.to_i - now.to_i

        next if e.from_time.to_datetime.to_i - now.to_i < 1770

        unless e.repeated
          e.repeated_number = 1
        end

        message = 'Your event will start in half an hour: '
        notification_message = "Your event #{e.title} will start in half an hour."

        count = count + 1
        send_event_notifications(e, message, 'event-detail', notification_message)
      }

      if count > 0
        puts "Info: #{count} dashboard records and notifications have been sent."
      end
    end
  end

  register Sinatra::ActiveRecordExtension
  register Sinatra::Namespace

  set :show_exceptions, :after_handler
  set :bind, '0.0.0.0'
  set :server, 'puma'
  set :sockets, {}
  set :protection, :except => [:json_csrf]
  set :logging, true

  options = { :address              => ENV['SMTP_SERVER'],
              :port                 => ENV['SMTP_PORT'] || 25,
              :domain               => ENV['SMTP_DOMAIN'] || ENV['SMTP_SERVER'],
              :user_name            => ENV['AUTH_EMAIL'],
              :password             => ENV['AUTH_EMAIL_PASSWORD'],
              :authentication       => 'plain',
              :enable_starttls_auto => true  }
  Mail.defaults do
    delivery_method :smtp, options
  end

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

  #set notifications to the checked status
  def mark_notification_as_read!
    notification = User.find(@userid).notifications
    @received_msg.each do |notify|
      notification.update(notify['id'], :checked => true);
    end
  end

  before do
    unless request.env['HTTP_X_USER'].nil?
      @userid = request.env['HTTP_X_USER'].to_i
    end

    if request.env['HTTP_SECRET_KEY'].nil?
      @secret_call = false
    else
      @secret_call = request.env['HTTP_SECRET_KEY'] == ENV['SECRET_KEY'] || request.env['HTTP_SECRET_KEY'] == 'secret_key'
    end
  end

  get '/socket' do
    login_required!
      if Faye::WebSocket.websocket?(request.env)
        ws = Faye::WebSocket.new(request.env)
        ws.on(:open) do |event|
          logger.info "open #{@userid}"
          settings.sockets[@userid] = ws
        end

        ws.on(:message) do |event|
          msg = event.data
          puts msg
          if msg != 'keep alive'
            begin
              @received_msg = JSON.parse(msg)
              mark_notification_as_read!
            rescue JSON::ParserError => e
              logger.error e
            end
          end
        end

        ws.on(:error) do |msg|
          logger.error msg
        end

        ws.on(:close) do |event|
          logger.info "close #{@userid}"
          settings.sockets.delete(@userid)
        end
        ws.rack_response
      end
  end

  get '/' do
    content_type 'text/html'
    erb :index, :locals => {:script_url => settings.script_url, :css_url => settings.css_url}
  end

  not_found do
    unless request.path_info.start_with?('/api/')
      status 200
      erb :index, :locals => {:script_url => settings.script_url, :css_url => settings.css_url}
    end
  end

  namespace '/api' do

    before do
      login_required! unless (%w(/api/users /api/login /).include?(request.path_info) || request.path_info =~ /\/user\/invitation.*/)

      content_type 'application/json'
      if request.media_type == 'application/json'
        body = request.body.read
        unless body.empty?
          @body = JSON.parse(body)
        end
      end
    end
  end

  # start the server if ruby file executed directly
  run! if app_file == $0
end

require_relative 'helpers/init'
require_relative 'models/init'
require_relative 'routes/init'
