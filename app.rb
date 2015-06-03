require 'sinatra/base'
require 'sinatra/activerecord'
require 'sinatra/namespace'
require 'rest_client'
require 'pony'
require 'bcrypt'
require 'date'
require 'rufus-scheduler'
require 'faye/websocket'
require 'resque'
require 'mail'
require 'sinatra/redis'

Faye::WebSocket.load_adapter('thin')

class App < Sinatra::Base

  configure :production do
    set :script_url, '/platform/_assets/main.js'
    set :css_url, '/platform/_assets/main.css'
    set :platform_url, 'www.rhinobird.workslan/platform'

    redis_url = ENV['REDISCLOUD_URL'] || ENV['OPENREDIS_URL'] || ENV['REDISGREEN_URL'] || ENV['REDISTOGO_URL']
    uri = URI.parse(redis_url)
    Resque.redis = Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)
    Resque.redis.namespace = 'resque:rhinobird'
    set :redis, redis_url
  end

  configure :development do
    set :script_url, 'http://localhost:2992/_assets/main.js'
    set :css_url, ''
    set :platform_url, 'localhost:8000/platform'

    redis_url = 'redis://localhost:6379'
    uri = URI.parse(redis_url)
    Resque.redis = Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)
    Resque.redis.namespace = 'resque:rhinobird'
    set :redis, redis_url
  end

  register Sinatra::ActiveRecordExtension
  register Sinatra::Namespace

  set :show_exceptions, :after_handler
  set :bind, '0.0.0.0'
  set :server, 'puma'
  set :sockets, {}
  set :protection, :except => [:json_csrf]
  set :logging, true

  options = { :address              => 'smtp.gmail.com',
              :port                 => 587,
              :domain               => 'www.gmail.com',
              :user_name            => 'rhinobird.worksap',
              :password             => 'worksapplication',
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
