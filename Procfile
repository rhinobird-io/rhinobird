web: bundle exec rackup -p $PORT
rake -T resque
QUEUE=notifiers rake resque:work
