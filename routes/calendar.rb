# encoding: utf-8


class App < Sinatra::Base
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

      notify = notification.to_json(:except => [:user_id])
      socket_id = u.id
      unless settings.sockets[socket_id].nil?
        EM.next_tick { settings.sockets[socket_id].send(notify) }
      end
    }
  end

  def notify(user, notify, subject, body)
    if settings.sockets[user.id].nil?
      Resque.enqueue(EmailQueue, 'rhinobird.worksap@gmail.com', 'li_ju@worksap.co.jp', subject, body)
    else
      settings.sockets[user.id].send(notify)
    end
  end

  namespace '/api' do
    get '/events' do
      today = Date.today

      user = User.find(@userid)

      all_events = Array.new
      all_events.concat user.events.where('status <> ?', Event.statuses[:trashed])

      user.teams.each { |t|
        all_events.concat t.events.where('status <> ?', Event.statuses[:trashed])
      }

      today_or_after_events = Array.new
      old_events = Array.new

      all_events.each { |e|
        e.repeated_number = 1

        repeated_number = e.get_repeated_number(today)

        next if e.repeated && e.repeated_exclusion.include?(repeated_number)

        if e.repeated
          puts "Repeated Event: #{e.title}"
          puts "Repeated Exclusion: #{e.repeated_exclusion}"
        end

        if e.repeated && e.from_time.to_date != today && repeated_number > 0
          day_diff = DateHelper.day_diff(today, e.from_time.to_date)
          new_event = Marshal::load(Marshal.dump(e))
          new_event.from_time = e.from_time + day_diff.days
          new_event.to_time = e.to_time + day_diff.days
          new_event.repeated_number = repeated_number
          today_or_after_events.push(new_event)
          #today_or_after_events.push(e)
        elsif e.from_time.to_date >= today
          today_or_after_events.push(e)
        elsif e.from_time.to_date < today
          old_events.push(e)
        end
      }

      result = Array.new
      if today_or_after_events.length >= 10
        result.concat today_or_after_events.sort! { |a, b| a.from_time <=> b.from_time }.first(10)
      else
        result.concat old_events.sort! { |a, b| a.from_time <=> b.from_time }.last(10 - today_or_after_events.length)
        result.concat today_or_after_events
      end

      result.to_json(
          json: Event,
          methods: [:repeated_number],
          include: {participants: {only: :id}, team_participants: {only: :id}}
      )
    end

    get '/events/after/:from_time' do
      from = DateTime.parse(params[:from_time])

      events = Array.new
      events.concat User.find(@userid).events.where('from_time > ? and status <> ?', from, Event.statuses[:trashed])

      User.find(@userid).teams.each { |t|
        events.concat t.events.where('from_time > ? and status <> ?', from, Event.statuses[:trashed])
      }

      events.each { |e|
        e.repeated_number = 1
      }

      events.sort! { |a, b| a.from_time <=> b.from_time }.
          first(5).
          to_json(
            json: Event,
            methods: [:repeated_number],
            include: {participants: {only: :id}, team_participants: {only: :id}})
    end

    get '/events/before/:from_time' do
      from = DateTime.parse(params[:from_time])

      puts 'Great'
      puts params[:from_time]

      events = Array.new
      events.concat User.find(@userid).events.where('from_time < ? and status <> ?', from, Event.statuses[:trashed])

      User.find(@userid).teams.each { |t|
        events.concat t.events.where('from_time < ? and status <> ?', from, Event.statuses[:trashed])
      }

      results = Array.new
      events.each { |e|
        if e.from_time < from
          e.repeated_number = 1
          results.push(e);
        end
      }

      results.sort! { |a, b| a.from_time <=> b.from_time }.
          first(5).
          to_json(
            json: Event,
            methods: [:repeated_number],
            include: {participants: {only: :id}, team_participants: {only: :id}})
    end

    get '/events/:eventId/:repeatedNumber' do
      if params[:eventId].nil? || params[:repeatedNumber].nil?
        404
      else
        e = Event.find(params[:eventId])

        if e.nil? || e.status == 'trashed'
          404
        elsif e.repeated
          event = e.get_repeated_event(params[:repeatedNumber])

          if event.nil? || event.repeated_exclusion.include?(params[:repeatedNumber].to_i)
            return 404
          end

          event.to_json(
              json: Event,
              methods: [:repeated_number],
              include: {participants: {only: :id}, team_participants: {only: :id}})
        else
          e.repeated_number = 1
          e.to_json(
              json: Event,
              methods: [:repeated_number],
              include: {participants: {only: :id}, team_participants: {only: :id}})
        end
      end
    end

    # Create Event
    post '/events' do
      uid = @userid
      event = Event.new(@body.except('participants'))

      notified_users = Array.new

      @body['participants']['teams'].each { |p|
        team = Team.find(p)
        event.team_participants << team
        team.users.each { |u|
          unless notified_users.include? u.id
            notified_users << u.id
          end
        }
      }

      @body['participants']['users'].each do |p|
        user = User.find(p)
        unless notified_users.include? user.id
          notified_users << user.id
          event.participants << user
        end
      end

      # Whether the event creator is also a participant by default?
      user_self = User.find(uid)
      unless notified_users.include? uid
        event.participants << user_self
        notified_users << uid
      end

      event.creator_id = uid
      event.status = 'created'
      event.save!

      ActiveRecord::Base.transaction do
        notified_users.each { |p|
          user = User.find(p)

          if event.creator_id == p
            message = 'You have created an event '
          else
            message = 'Invited you to event '
          end

          user.dashboard_records.create!({content: message,
                                          from_user_id: uid,
                                          has_link: true,
                                          link_url: 'event-detail',
                                          link_param: event.to_json(methods: [:repeated_number], only: [:id]),
                                          link_title: event.title})

          notification = user.notifications.create!({content: message + event.title, from_user_id: uid})

          notify = notification.to_json(:except => [:user_id])

          if event.creator_id != p
            notify(
                user,
                notify,
                "[Rhinobird] #{user_self.realname} invited you to event #{event.title}",
                "Hello <b>#{user.realname}</b>:<br/>" +
                  "&ensp;#{user_self.realname} invited you to event #{event.title}." +
                  "&ensp;You can see details from this <a href='http://www.rhinobird.workslan/platform/calendar/events/#{event.id}/1'>link</a>.")
          end
        }
      end

      event.repeated_number = 1
      event.to_json(
          json: Event,
          methods: [:repeated_number],
          include: {participants: {only: :id}, team_participants: {only: :id}})
    end

    delete '/events/:event_id/?:repeated_number?' do
      event = Event.find(params[:event_id])
      if @userid == event.creator_id
        uid = @userid

        event.participants.each { |p|
          user = User.find(p.id)

          if event.creator_id == p.id
            content = 'You have canceled the event ' + event.title
          else
            content = 'has canceled the event ' + event.title
          end

          user.dashboard_records.create!({content: content, from_user_id: uid})
          notification = user.notifications.create!({content: content, from_user_id: uid})
          notify = notification.to_json(:except => uid)
          socket_id = p.id
          unless settings.sockets[socket_id].nil?
            EM.next_tick { settings.sockets[socket_id].send(notify) }
          end
        }

        repeated_number = params[:repeated_number]

        if repeated_number.nil?
          event.status = 'trashed'
        else
          unless event.repeated_exclusion.include?(repeated_number.to_i)
            event.repeated_exclusion << repeated_number.to_i
          end
        end

        event.save!

        content_type 'text/plain'
        200
      else
        403
      end
    end

    put '/events/restore/:event_id/?:repeated_number?' do
      if params[:event_id].nil?
        404
      else
        event = Event.find(params[:event_id])
        if event.nil?
          return 404
        end

        if @userid == event.creator_id
          repeated_number = params[:repeated_number]

          if event.repeated && !repeated_number.nil?
            if event.repeated_exclusion.include?(repeated_number.to_i)
              event.repeated_exclusion.delete(repeated_number.to_i)
              if event.repeated_exclusion.length === 0
                event.repeated_exclusion = [0]
              end
            end
          else
            event.status = 'created'
          end

          event.save!

          if event.repeated && !repeated_number.nil?
            event = event.get_repeated_event(repeated_number.to_i)
          else
            event.repeated_number = 1
          end

          event.to_json(
              json: Event,
              methods: [:repeated_number],
              include: {participants: {only: :id}, team_participants: {only: :id}})
        else
          403
        end
      end

    end
  end
end