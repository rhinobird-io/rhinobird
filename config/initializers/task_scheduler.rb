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

scheduler = Rufus::Scheduler.new

# Check events that are not full day.
scheduler.every '30s' do
  now = Time.now
  ten_minutes = 10 * 60
  ten_minutes_later = now + ten_minutes

  events = Event.where('from_time > ? and from_time <= ? and full_day = ?', now, ten_minutes_later, false)

  events.each { |e|
  	next if e.from_time - now < 570
  	
  	participants = e.participants
  	team_participants = e.team_participants

  	message = 'Your event will start in ten minutes: '
  	
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
			content: message, 
			from_user_id: u.id,
        	has_link: true,
        	link_url: '#/calendar/' + e.id.to_s,
        	link_title: e.title
    	})

		notification_message = 'Your event ' + e.title + ' will start in ten minutes.'
    	notification = u.notifications.create!({content: notification_message, from_user_id: u.id})
      
	    # notify = notification.to_json(:except => [:user_id])
	    # socket_id = u.id
	    # unless settings.sockets[socket_id].nil?
	    #   EM.next_tick { settings.sockets[socket_id].send(notify) }
	    # end
	}
  }
end

# Check full day events
scheduler.every '1d' do
end

scheduler.join