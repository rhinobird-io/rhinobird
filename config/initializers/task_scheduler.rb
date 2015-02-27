require 'sinatra/base'
require 'sinatra/namespace'
require 'sinatra/activerecord'
require 'sinatra-websocket'
require './models/plugin.rb'
require './models/team.rb'
require './models/user.rb'
require './models/users_teams.rb'
require './models/dashboard_record'
require './models/notification'
require './models/local_avatar'
require './models/event'
require './models/appointment'
require './models/team_appointment'
require './models/invitation'
require 'rufus-scheduler'

def send_event_notification (e, dashboard_message, dashboard_link, notification_message)
  	participants = e.participants
  	team_participants = e.team_participants

  	users = Array.new

  	participants.each { |p|
  		users << p
  	}

	team_participants.each { |tp|
		team = Team.find(tp.id)
		users.concat team.users
		puts users.size
	}

	users.each { |u|
		u.dashboard_records.create!({
			content: dashboard_message, 
			from_user_id: u.id,
        	has_link: true,
        	link_url: dashboard_link,
        	link_title: e.title
    	})

    	notification = u.notifications.create!({content: notification_message, from_user_id: u.id})
      
	    # notify = notification.to_json(:except => [:user_id])
	    # socket_id = u.id
	    # unless settings.sockets[socket_id].nil?
	    #   EM.next_tick { settings.sockets[socket_id].send(notify) }
	    # end
	}
end

scheduler = Rufus::Scheduler.new

scheduler.every '2s' do
  puts 'Hello'
end
# Check events that are not full day.
scheduler.every '30s' do
  now = Time.now
  ten_minutes = 10 * 60
  ten_minutes_later = now + ten_minutes

  events = Event.where('from_time >= ? and from_time <= ? and full_day = ?', now, ten_minutes_later, false)

  events.each { |e|
  	next if e.from_time - now < 575
  	
  	message = 'Your event will start in ten minutes: '
	notification_message = 'Your event ' + e.title + ' will start in ten minutes.'
  	
  	send_event_notification(e, message, '#/calendar/' + e.id.to_s, notification_message)
  }
end

# Check full day events at everyday's 12:00
scheduler.cron '00 12 * * *' do
  now = Time.now

  events = Event.where('from_time > ? and full_day = ?', now, true)
  events.each { |e|
  	from_time = e.from_time
  	one_day_before = from_time - 24 * 60 * 60
  	
  	if one_day_before.year == now.year and one_day_before.month == now.month and one_day_before.day == now.day 
  		dashboard_message = 'Your full day event will start at tommorrow: '
  		notification_message = 'Your full day event ' + e.title + ' will start at tommorrow.'

  		send_event_notification(e, dashboard_message, '#/calendar/' + e.id.to_s, notification_message)
  	end
  }
end

scheduler.join