require 'faker'
require "bcrypt"

include BCrypt

namespace :db do
  desc 'Fill database with sample data'
  task :populate => :environment do
    Rake::Task['db:reset'].invoke
    3.times do
      team = Team.create!({name: Faker::Company.name})
      10.times do
        realname = Faker::Name.name
        user = team.users.create!({realname: realname, email: Faker::Internet.email(realname), encrypted_password: Password.create("123")})
        3.times do
          user.dashboard_records.create!({content: Faker::Lorem.sentence, from_user_id: Random.rand(1..30)})
          user.notifications.create!({content: Faker::Lorem.sentence, from_user_id: Random.rand(1..30)})
        end
      end
    end

    5.times do
      plugin = Plugin.create!({name: Faker::App.name, description: Faker::Lorem.paragraph, author: Faker::App.author, url: Faker::Internet.url})
    end

    5.times do
      Event.create!({
                        title: Faker::Lorem.sentence,
                        description: Faker::Lorem.paragraph,
                        full_day: true,
                        period: false,
                        from: Faker::Date.between(2.days.ago, 2.days.from_now)})
    end
    5.times do
      Event.create!({
                        title: Faker::Lorem.sentence,
                        description: Faker::Lorem.paragraph,
                        full_day: false,
                        period: false,
                        from: Faker::Time.between(2.days.ago, 2.days.from_now)})
    end
    5.times do
      Event.create!({
                        title: Faker::Lorem.sentence,
                        description: Faker::Lorem.paragraph,
                        full_day: false,
                        period: true,
                        from: Faker::Time.between(1.hours.from_now, 2.hours.from_now),
                        to: Faker::Time.between(3.hours.from_now, 4.hours.from_now)
                    })
    end
    for idx in 1..15
        Appointment.create!(event_id: idx, participant_id: 1)
        4.times do
            Appointment.create!(event_id: idx, participant_id: Random.rand(2..30))
        end
    end
  end
end
