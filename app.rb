require 'sinatra/base'
require 'sinatra/namespace'
require 'sinatra/activerecord'
require './models/plugin.rb'
require './models/team.rb'
require './models/user.rb'
require './models/users_teams.rb'
require './models/dashboard_record'
require './models/vote.rb'
require './models/question.rb'

class App < Sinatra::Base

  register Sinatra::ActiveRecordExtension
  register Sinatra::Namespace

  set :show_exceptions, :after_handler
  set :bind, '0.0.0.0'

  I18n.config.enforce_available_locales = true

  error ActiveRecord::RecordInvalid do
    status 400
    body env['sinatra.error'].message
  end

  get '/' do
    content_type 'text/html'
    send_file File.join(settings.public_folder, 'index.html')
  end

  before do
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
      #plugin.start
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

    get '/users' do
      User.all.to_json
    end

    post '/users' do
      User.create!(@body)
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

    # start the server if ruby file executed directly
    run! if app_file == $0

    # vote related services
    get '/votes' do
      Vote.all.to_json
    end

    #create new vote
    post '/votes' do
      Vote.create!(@body)
    end

    get '/votes/:voteId/questions' do
      Question.where(vote_id: params[:voteId]).all.to_json
    end

    post '/votes/:voteId/questions' do
      vote = Vote.find(params[:voteId])
      question = Question.create!(@body)
      vote.question << question
      200
    end

    # get all user related to specific vote
    get '/votes/:voteId/users' do
      Vote.find(params[:voteId]).users.to_json
    end

    # register all user related to specific vote
    post '/votes/:voteId/users' do
      Vote.find(params[:voteId]).users.create!(@body)
    end

    get '/users/:userId/votes' do
      User.find(params[:userId]).votes.to_json
    end

    post '/users/:userId/votes' do
      User.find(params[:userId]).votes.create!(@body)
    end
  end

end