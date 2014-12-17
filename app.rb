require 'sinatra'
require "sinatra/activerecord"
#require 'sequel'
require './config/environments'

class App < Sinatra::Base

    get '/' do
        "Hello"
    end

    post '/upload' do
        p params['file'][:filename]
        p params['file'][:tempfile]
        "The file was successfully uploaded!"
    end

end