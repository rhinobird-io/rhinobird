require 'sinatra'
require 'sinatra/namespace'
require "sinatra/activerecord"
#require 'sequel'
require './config/environments'
require './models/plugin.rb'

class App < Sinatra::Base

  register Sinatra::Namespace

  set :show_exceptions, :after_handler

  error ActiveRecord::RecordInvalid do
    status 400
    body env['sinatra.error'].message
  end

  get '/' do
    "Hello"
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
      "The file was successfully uploaded!"
    end

    get '/plugins' do
      Plugin.all.to_json
    end

    post '/plugins' do
      p "Entering"
      Plugin.create!(@body)
      200
    end
  end

end