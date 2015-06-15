# encoding: utf-8
class App < Sinatra::Base
  namespace '/api' do
    #get all notifications for one user
    get '/users/:userId/notifications' do
      User.find(params[:userId]).notifications.to_json
    end

    #get specified part of notifications for one user
    get '/users/:userId/notifications/:startIndex/:limit' do
      return_obj = {}
      notifications = User.find(params[:userId]).notifications
      if params[:startIndex] == 0
        if notifications.where(checked: false).count < params[:limit]
          return_obj['notifications'] = notifications.limit(params[:limit]).offset(0)
        else
          return_obj['notifications'] = notifications.where(checked: false)
        end
      else
        return_obj['notifications'] = notifications.limit(params[:limit]).offset(params[:startIndex])
      end
      return_obj['total'] = notifications.count
      return_obj.to_json
    end

    # add a notification to one user
    post '/users/:userId/notifications' do
      user = User.find(params[:userId])
      notification = user.notifications.create!(@body)
      notify = notification.to_json(:except => [:user_id])
      socket_id = params[:userId].to_i
      notify(user, notify, @body['email_subject'], @body['email_body'])
      200
    end

    # add a notification to many users
    post '/users/notifications' do
      user_ids = @body["users"] || []
      team_ids = @body['teams'] || []
      content =@body["content"]
      content["from_user_id"] = @userid
      users = Set.new
      unless @body["url"].nil?
        content["url"] = @body["url"]
      end
      user_ids.each do |userid|
        user = User.find(userid.to_i)
        users.add(user)
      end
      team_ids.each do |teamId|
        team = Team.find(teamId)
        users.merge(team.get_all_users)
      end
      users.each do |user|
        notification = user.notifications.create!(content)
        notify = notification.to_json(:except => [:user_id])
        notify(user, notify, @body['email_subject'], @body['email_body'])
      end
      200
    end
  end
end