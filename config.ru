require './app'
require 'resque/server'

run Rack::URLMap.new \
  '/'       => App,
  '/resque' => Resque::Server.new