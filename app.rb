require 'sinatra'
require 'sinatra/namespace'
require 'sinatra/activerecord'
require './config/environments'
require './models/plugin.rb'
require './models/team.rb'
require './models/user.rb'
require './models/users_teams.rb'

class App < Sinatra::Base

  register Sinatra::Namespace

  set :show_exceptions, :after_handler

  error ActiveRecord::RecordInvalid do
    status 400
    body env['sinatra.error'].message
  end

  get '/' do
    send_file File.join(settings.public_folder, 'index.html')
  end

  before do
    body = request.body.read
    unless body.empty?
      @body = JSON.parse(body)
    end
  end

  namespace '/developer' do

    get '/?' do
      send_file File.join(settings.public_folder, 'developer/index.html')
    end

    post '/upload' do
      p params['file'][:filename]
      p params['file'][:tempfile]
      'The file was successfully uploaded!'
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
    get "/teams/:teamId/users" do
      Team.find(params[:teamId]).users.to_json
    end

    # add a user to a team
    post "/teams/:teamId/users/:userId" do
      team = Team.find(params[:teamId])
      user = User.find(params[:userId])
      # it does not work now
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
    get "/users/:userId/teams" do
      User.find(params[:userId]).teams.to_json
    end
  end

end