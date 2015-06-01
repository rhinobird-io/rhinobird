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
      notification = User.find(params[:userId]).notifications.create!(@body)
      notify = notification.to_json(:except => [:user_id])
      socket_id = params[:userId].to_i
      unless settings.sockets[socket_id].nil?
        EM.next_tick { settings.sockets[socket_id].send(notify) }
      end
      200
    end

    # add a notification to many users
    post '/users/notifications' do
      users = @body["users"]
      content =@body["content"]
      content["from_user_id"] = @userid

      unless @body["url"].nil?
        content["url"] = @body["url"]
      end

      users.each do |user|
        notification = User.find(user.to_i).notifications.create!(content)
        notify = notification.to_json(:except => [:user_id])
        unless settings.sockets[user.to_i].nil?
          EM.next_tick { settings.sockets[user.to_i].send(notify) }
        end
      end
      200
    end
  end
end