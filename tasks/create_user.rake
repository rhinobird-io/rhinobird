require 'faker'
require 'bcrypt'

include BCrypt

namespace :db do
  desc 'Create a user'
  task :create_user, [:name] => :environment do |t, args|
    ActiveRecord::Base.transaction do
        User.create!(realname: args[:name], name: args[:name], email: "#{args[:name]}@worksap.co.jp", encrypted_password: Password.create(args[:name]))
    end
  end
end
