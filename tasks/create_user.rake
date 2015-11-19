require 'faker'
require 'bcrypt'
require 'json'

include BCrypt

namespace :db do
  desc 'Create a user'
  task :create_user, [:name] => :environment do |t, args|
    ActiveRecord::Base.transaction do
        User.create!(realname: args[:name], name: args[:name], email: "#{args[:name]}@worksap.co.jp", encrypted_password: Password.create(args[:name]))
    end
  end

  task :test_email, [:file] => :environment do |t, args|
    json_file = File.read(args[:file])
    data_parsed = JSON.parse(json_file)
    data_parsed.each { |account|
        # Create account
        username = account['address'].split("@").first

        err = nil
        begin
            User.create!(realname: username, name: username, email: account['address'], encrypted_password: Password.create(username))
        rescue ActiveRecord::RecordInvalid => error
            puts 'Failed to create account ' + account['address'] + ', ' + error.record.errors.full_messages.join(",")
            err = error
        end
        next if err

        Mail.deliver do
          from "rhinobird.worksap@gmail.com"
          to account['address']
          subject 'test email'
          content_type 'text/html; charset=UTF-8'
          body 'hello world'
        end

        puts 'Create account and send email successfully for ' + account['email']
    }
  end
end
