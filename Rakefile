ENV['DISABLE_RUFUS'] = 'TRUE'

require 'sinatra/activerecord/rake'
require 'faker'
require './app'
require 'resque/tasks'

task 'resque:setup' do
  ENV['QUEUE'] = '*'
end



Dir.glob('tasks/*.rake').each { |r| load r}

begin
  require 'rspec/core/rake_task'
  desc 'Run Respec Test'
  RSpec::Core::RakeTask.new(:spec) do |t|
    t.pattern = Dir.glob('spec/**/*_spec.rb')
    t.rspec_opts = '--format documentation'
  end
rescue LoadError
end