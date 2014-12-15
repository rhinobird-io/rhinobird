require 'sinatra'

get '/' do
    "Hello"
end

post '/upload' do
    p params['file'][:filename]
    p params['file'][:tempfile]
    "The file was successfully uploaded!"
end