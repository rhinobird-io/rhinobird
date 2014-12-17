require 'sequel'

configure :development do
    set :db, Sequel.connect("sqlite://dev.db")
end