require 'sinatra/activerecord/rake'
require 'faker'
require './app'
require 'resque/tasks'

task 'resque:setup' do
  ENV['QUEUE'] = '*'
end

Dir.glob('tasks/*.rake').each { |r| load r}