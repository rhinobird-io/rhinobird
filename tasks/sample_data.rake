require 'faker'

namespace :db do
  desc 'Fill database with sample data'
  task :populate => :environment do
    Rake::Task['db:reset'].invoke
    3.times do
      team = Team.create!({name: Faker::Company.name})
      10.times do
        realname = Faker::Name.name
        user = team.users.create!({name: Faker::Internet.user_name(realname, %w(_)), realname: realname, email: Faker::Internet.email(realname)})
        3.times do
          user.dashboard_records.create!({content: Faker::Lorem.sentence})
        end
      end
    end
  end
end