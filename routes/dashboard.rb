# encoding: utf-8
class App < Sinatra::Base
  namespace '/api' do
    get '/users/:userId/dashboard_records' do
      before = params[:before]
      if before.nil?
        User.find(params[:userId]).dashboard_records.limit(20).to_json
      else
        User.find(params[:userId]).dashboard_records.where('id < ?', before).limit(20).to_json
      end
    end

    post '/users/:userId/dashboard_records' do
      User.find(params[:userId]).dashboard_records.create!(@body)
    end

    post '/users/dashboard_records' do
      users = @body["users"]
      content =@body["content"]
      content["from_user_id"] = @userid
      users.each do |user|
        record = User.find(user).dashboard_records.create!(content)
      end
      200
    end
  end
end