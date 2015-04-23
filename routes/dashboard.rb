# encoding: utf-8
class App < Sinatra::Application
  namespace '/api' do
    get '/users/:userId/dashboard_records' do
      User.find(params[:userId]).dashboard_records.to_json
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