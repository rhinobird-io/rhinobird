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

    get '/teams' do
      Team.all.to_json
    end

    post '/teams' do
      Team.create!(@body)
    end

    #get all users in a team
    get "/teams/:teamId/users" do
      team = Team.find(params[:teamId])
      team.users_teams.map {|item| User.find(item.user_id)}.to_json
    end

    # add a user to a team
    post "/teams/:teamId/users/:userId" do
      team = Team.find(params[:teamId])
      user = User.find(params[:userId])
      UsersTeam.create(user_id: user.id, team_id: team.id) unless user.nil?
    end

    get '/users' do
      User.all.to_json
    end

    post '/users' do
      User.create!(@body)
    end

    #get all team the user attend
    get "/users/:userId/teams" do
      user = User.find(params[:userId])
      user.users_teams.map { |item| Team.find(item.team_id)}.to_json
    end

  end

end