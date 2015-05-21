require 'sinatra/base'
require 'sinatra/namespace'
require 'sinatra/activerecord'
require 'sinatra-websocket'
require_relative 'helpers/init'
require_relative 'models/init'
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
		u.dashboard_records.create!(
			{
				content: dashboard_message,
				from_user_id: u.id,
				has_link: true,
				link_url: dashboard_link,
				link_title: e.title,
				link_param: e.to_json(methods: [:repeated_number], only: [:id]),
    	}
		)

		notification = u.notifications.create!({content: notification_message, from_user_id: u.id})
      
		# notify = notification.to_json(:except => [:user_id])
		# socket_id = u.id
		# unless settings.sockets[socket_id].nil?
		# 	EM.next_tick { settings.sockets[socket_id].send(notify) }
		# end
	}
end

scheduler = Rufus::Scheduler.new

# Check events that are not full day.
scheduler.every '30s' do
  now = DateTime.now
  half_an_hour = 30.minute
	half_an_hour_later = now + half_an_hour

  events = Event.where('from_time >= ? and from_time <= ? and full_day = ? and repeated = ?', now, half_an_hour_later, false, false)
	repeated_events = Event.where('repeated = ?', true)

  repeated_events.each { |e|
    repeated_number = e.get_repeated_number(Date.today)
		re = e.get_repeated_event(repeated_number)

    if !re.nil? && re.from_time.to_datetime >= now && re.from_time.to_datetime <= half_an_hour_later
      e.repeated_number = repeated_number
      events.push(e)
    end
  }

  count = 0
  events.each { |e|
    puts e.from_time.to_datetime.to_i - now.to_i

		next if e.from_time.to_datetime.to_i - now.to_i < 1775

    unless e.repeated
      e.repeated_number = 1
    end

  	message = 'Your event will start in half an hour: '
	  notification_message = "Your event #{e.title} will start in half an hour."

    count = count + 1
  	send_event_notification(e, message, 'event-detail', notification_message)
  }

  if count > 0
		puts "Info: #{count} dashboard records and notifications have been sent."
	end
end

# Check full day events at everyday 12:00
scheduler.cron '00 12 * * *' do
  now = Time.now

  events = Event.where('from_time > ? and full_day = ?', now, true)
  events.each { |e|
  	from_time = e.from_time
  	one_day_before = from_time - 24 * 60 * 60
  	
  	if one_day_before.year == now.year and one_day_before.month == now.month and one_day_before.day == now.day 
  		dashboard_message = 'Your full day event will start at tomorrow: '
  		notification_message = "Your full day event #{e.title} will start at tomorrow."

  		send_event_notification(e, dashboard_message, 'event-detail', notification_message)
  	end
  }
end

scheduler.join