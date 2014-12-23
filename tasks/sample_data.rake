require 'faker'

namespace :db do
  desc "Fill database with sample data"
  task :populate => :environment do
    Rake::Task['db:reset'].invoke

    team = Team.create!({name: Faker::Company.name})
    10.times do
      realname = Faker::Name.name
      team.users.create!({name: Faker::Internet.user_name(realname, %w(_)), realname: realname, email: Faker::Internet.email(realname)})
    end
  end
end