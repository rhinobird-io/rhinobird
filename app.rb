require 'sinatra/base'
require 'sinatra/activerecord'
require 'sinatra/namespace'
require 'sinatra-websocket'
require 'rest_client'
require 'pony'
require 'bcrypt'
require 'date'
require 'rufus-scheduler'

class App < Sinatra::Base

  register Sinatra::ActiveRecordExtension
  register Sinatra::Namespace
  #auth_url = ENV['AUTH_URL'] || 'http://localhost:8000/auth'
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
    if request.websocket?
      request.websocket do |ws|
        ws.onopen do
          settings.sockets[@userid] = ws
        end
        ws.onmessage do |msg|
          if msg != 'keep alive'
            @received_msg = JSON.parse(msg)
            mark_notification_as_read!
          end
        end
        ws.onclose do
          settings.sockets.delete(ws)
        end
      end
    end
  end

  get '/' do
    content_type 'text/html'
    erb :index, :locals => {:script_url => 'http://localhost:2992/_assets/main.js'}
  end

  not_found do
    unless request.path_info.start_with?('/api/')
      status 200
      erb :index, :locals => {:script_url => 'http://localhost:2992/_assets/main.js'}
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
