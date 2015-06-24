require 'faker'
require 'bcrypt'

include BCrypt

namespace :db do
  desc 'Fill database with sample data'
  task :populate => :environment do
    Rake::Task['db:reset'].invoke
    ActiveRecord::Base.transaction do

      sh_all = Team.create!({name: 'Shanghai All'})
      hue = sh_all.teams.create!({name: 'HUE'})
      ate = sh_all.teams.create!({name: 'ATE'})
      oss = ate.teams.create!({name:'OSS'})
      ocrus = ate.teams.create!({name:'OCRUS'})
      hue.teams.create!({name:'HUE Test'})
      hue.teams.create!({name:'Magic Paste'})
      hue.teams.create!({name:'ESS'})

      3.times do
        realname = Faker::Name.name
        oss.users.create!({realname: realname, name: Faker::Internet.user_name(realname), email: Faker::Internet.email(realname), encrypted_password: Password.create('123')})
      end

      3.times do
        realname = Faker::Name.name
        ocrus.users.create!({realname: realname, name: Faker::Internet.user_name(realname), email: Faker::Internet.email(realname), encrypted_password: Password.create('123')})
      end
      3.times do
        realname = Faker::Name.name
        ate.users.create!({realname: realname, name: Faker::Internet.user_name(realname), email: Faker::Internet.email(realname), encrypted_password: Password.create('123')})
      end

      3.times do
        team = Team.create!({name: Faker::Company.name})
        10.times do
          realname = Faker::Name.name
          user = team.users.create!({realname: realname, name: Faker::Internet.user_name(realname), email: Faker::Internet.email(realname), encrypted_password: Password.create('123')})
          3.times do
            user.dashboard_records.create!({content: Faker::Lorem.sentence, from_user_id: Random.rand(1..30)})
            user.notifications.create!({content: Faker::Lorem.sentence, from_user_id: Random.rand(1..30)})
          end
        end
      end

      5.times do
        plugin = Plugin.create!({name: Faker::App.name, description: Faker::Lorem.paragraph, author: Faker::App.author, url: Faker::Internet.url})
      end

      # Full day events
      5.times do
        Event.create!({
                          title: Faker::Lorem.sentence,
                          description: Faker::Lorem.paragraph,
                          full_day: true,
                          period: false,
                          from_time: Faker::Date.between(2.days.ago, 2.days.from_now)})
      end

      # Normal events
      5.times do
        Event.create!({
                          title: Faker::Lorem.sentence,
                          description: Faker::Lorem.paragraph,
                          full_day: false,
                          period: false,
                          from_time: Faker::Time.between(2.days.ago, 2.days.from_now)})
      end

      # Period events
      5.times do
        Event.create!({
                          title: Faker::Lorem.sentence,
                          description: Faker::Lorem.paragraph,
                          full_day: false,
                          period: true,
                          from_time: Faker::Time.between(1.hours.from_now, 2.hours.from_now),
                          to_time: Faker::Time.between(3.hours.from_now, 4.hours.from_now)
                      })
      end

      # Repeated events
      # Daily repeated events, never ends
      3.times do
        Event.create!({
                          title: Faker::Lorem.sentence,
                          description: Faker::Lorem.paragraph,
                          full_day: false,
                          period: false,
                          from_time: Faker::Time.between(1.hours.from_now, 2.hours.from_now),
                          to_time: Faker::Time.between(3.hours.from_now, 4.hours.from_now),
                          repeated: true,
                          repeated_type: 'Daily',
                          repeated_frequency: Faker::Number.number(1).to_i + 1,
                          repeated_end_type: 'Never'
                      })
      end

      # Daily repeated events, ends after several occurrences
      3.times do
        Event.create!({
                          title: Faker::Lorem.sentence,
                          description: Faker::Lorem.paragraph,
                          full_day: false,
                          period: false,
                          from_time: Faker::Time.between(1.hours.from_now, 2.hours.from_now),
                          to_time: Faker::Time.between(3.hours.from_now, 4.hours.from_now),
                          repeated: true,
                          repeated_type: 'Daily',
                          repeated_frequency: Faker::Number.number(1).to_i  + 1,
                          repeated_end_type: 'Occurrence',
                          repeated_times: Faker::Number.number(2).to_i
                      })
      end

      # Daily repeated events, ends until certain date
      3.times do
        Event.create!({
                          title: Faker::Lorem.sentence,
                          description: Faker::Lorem.paragraph,
                          full_day: false,
                          period: false,
                          from_time: Faker::Time.between(1.hours.from_now, 2.hours.from_now),
                          to_time: Faker::Time.between(3.hours.from_now, 4.hours.from_now),
                          repeated: true,
                          repeated_type: 'Daily',
                          repeated_frequency: Faker::Number.number(1).to_i  + 1,
                          repeated_end_type: 'Date',
                          repeated_end_date: Faker::Date.between(100.days.from_now, 500.days.from_now),
                      })
      end

      # Weekly repeated events
      5.times do
        Event.create!({
                          title: Faker::Lorem.sentence,
                          description: Faker::Lorem.paragraph,
                          full_day: false,
                          period: false,
                          from_time: Faker::Time.between(1.hours.from_now, 2.hours.from_now),
                          to_time: Faker::Time.between(3.hours.from_now, 4.hours.from_now),
                          repeated: true,
                          repeated_type: 'Weekly',
                          repeated_on: '["Sun", "Mon", "Fri"]',
                          repeated_frequency: Faker::Number.number(1).to_i  + 1,
                          repeated_end_type: 'Occurrence',
                          repeated_times: Faker::Number.number(2).to_i
                      })
      end

      # Monthly repeated events, repeated by day of month
      3.times do
        Event.create!({
                          title: Faker::Lorem.sentence,
                          description: Faker::Lorem.paragraph,
                          full_day: false,
                          period: false,
                          from_time: Faker::Time.between(1.hours.from_now, 2.hours.from_now),
                          to_time: Faker::Time.between(3.hours.from_now, 4.hours.from_now),
                          repeated: true,
                          repeated_type: 'Monthly',
                          repeated_by: 'Month',
                          repeated_frequency: Faker::Number.number(1).to_i + 1,
                          repeated_end_type: 'Never'
                      })
      end

      # Monthly repeated events, repeated by day of week
      3.times do
        Event.create!({
                          title: Faker::Lorem.sentence,
                          description: Faker::Lorem.paragraph,
                          full_day: false,
                          period: false,
                          from_time: Faker::Time.between(1.hours.from_now, 2.hours.from_now),
                          to_time: Faker::Time.between(3.hours.from_now, 4.hours.from_now),
                          repeated: true,
                          repeated_type: 'Monthly',
                          repeated_by: 'Week',
                          repeated_frequency: Faker::Number.number(1).to_i + 1,
                          repeated_end_type: 'Never'
                      })
      end

      # Yearly repeated events, repeated by day of week
      5.times do
        Event.create!({
                          title: Faker::Lorem.sentence,
                          description: Faker::Lorem.paragraph,
                          full_day: false,
                          period: false,
                          from_time: Faker::Time.between(1.hours.from_now, 2.hours.from_now),
                          to_time: Faker::Time.between(3.hours.from_now, 4.hours.from_now),
                          repeated: true,
                          repeated_type: 'Yearly',
                          repeated_frequency: Faker::Number.number(1).to_i + 1,
                          repeated_end_type: 'Never'
                      })
      end

      for idx in 1..40
          Appointment.create!(event_id: idx, participant_id: 1)
          4.times do
              Appointment.create!(event_id: idx, participant_id: Random.rand(2..30))
          end
      end

      1.times do
        realname = 'lalala'
        oss.users.create!({realname: realname, name: Faker::Internet.user_name(realname), email: 'haha@haha.com', encrypted_password: Password.create('123')})
      end
    end
  end
end
