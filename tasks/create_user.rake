require 'faker'
require 'bcrypt'
require 'json'
require 'erb'

include BCrypt

namespace :db do
  desc 'Create a user'
  task :create_user, [:name] => :environment do |t, args|
    ActiveRecord::Base.transaction do
        u = User.create!(realname: args[:name], name: args[:name], email: "#{args[:name]}@worksap.co.jp", encrypted_password: Password.create(args[:name]))
        t = Team.find_by_name("Guest")
        t.users << u
        t.save!
    end
  end

  desc 'Init password to username'
  task :init_password, [:name] => :environment do |t, args|
    ActiveRecord::Base.transaction do
      User.find_by_name(args[:name]).update(encrypted_password: Password.create(args[:name]))
      puts 'init password finished successfully'
    end
  end

  task :batch_import, [:file] => :environment do |t, args|
    json_file = File.read(args[:file])
    data_parsed = JSON.parse(json_file)
    t = Team.find_by_name("Guest")
    data_parsed.each { |account|
        # Create account
        username = account['address'].split("@").first

        begin
            u = User.create!(realname: username, name: username, email: account['address'], encrypted_password: Password.create(username))
            t.users << u
            MyLogger.info('Account created successfully for email ' + account['address'])
        rescue ActiveRecord::RecordInvalid => error
            MyLogger.error('Failed to create account for ' + account['address'] + ', ' + error.record.errors.full_messages.join(","))
            next
        end


        controller = AccountBinding.new(username, username, account['address'])
        Mail.deliver do
          from "rhinobird.worksap@gmail.com"
          to account['address']
          subject 'Your RhinoBird account has been created!'
          content_type 'text/html; charset=UTF-8'
          body ERB.new(File.read('./views/email/account_created.erb')).result(controller.get_binding)
        end
        MyLogger.info('Send account data email successfully for ' + account['address'])
    }
    t.save!
  end

  class AccountBinding
    attr_reader :username, :password, :email
    def initialize(username, password, email)
      @username = username
      @password = password
      @email = email
    end

    def get_binding
      binding
    end
  end
end
