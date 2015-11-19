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

  task :test_email => :environment do
    data = '[{"selected":false,"address":"bai_y@worksap.co.jp","name":"","groups":[]},{"selected":false,"address":"chen_c@worksap.co.jp","name":"","groups":[]}]'
    JSON.parse('')
    Mail.deliver do
      from "rhinobird.worksap@gmail.com"
      to 'wang_bo@worksap.co.jp'
      subject 'test email'
      content_type 'text/html; charset=UTF-8'
      body 'hello world'
    end
  end
end
