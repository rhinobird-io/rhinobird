# encoding: utf-8

class App < Sinatra::Base
  namespace '/api' do
    get '/events' do
      today = Date.today

      user = User.find(@userid)

      all_events = Array.new
      all_events.concat user.events

      user.teams.each { |t|
        all_events.concat t.events
      }

      today_or_after_events = Array.new
      old_events = Array.new

      all_events.each { |e|
        e.repeated_number = 1

        repeated_number = e.get_repeated_number(today)
        if e.repeated && e.from_time.to_date != today && repeated_number > 0
          day_diff = DateHelper.day_diff(today, e.from_time.to_date)
          new_event = Marshal::load(Marshal.dump(e))
          new_event.from_time = e.from_time + day_diff.days
          new_event.to_time = e.to_time + day_diff.days
          new_event.repeated_number = repeated_number
          today_or_after_events.push(new_event)
          today_or_after_events.push(e)
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
      events.concat User.find(@userid).events.where('from_time > ?', from)

      User.find(@userid).teams.each { |t|
        events.concat t.events.where('from_time > ?', from)
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
      events.concat User.find(@userid).events.where('from_time < ?', from)

      User.find(@userid).teams.each { |t|
        events.concat t.events.where('from_time < ?', from)
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

        if e.nil?
          404
        else
          event = e.get_repeated_event(params[:repeatedNumber])

          if event.nil?
            return 404
          end

          event.to_json(
              json: Event,
              methods: [:repeated_number],
              include: {participants: {only: :id}, team_participants: {only: :id}})
        end
      end
    end

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

      event.save!

      event.repeated_number = 1

      notified_users.each { |p|
        user = User.find(p)

        if event.creator_id == p
          message = 'You have created an event '
        else
          message = 'Invited you to the event '
        end

        user.dashboard_records.create!({content: message,
            from_user_id: uid,
            has_link: true,
            link_url: 'event-detail',
            link_param: event.to_json(methods: [:repeated_number], only: [:id]),
            link_title: event.title})

        notification = user.notifications.create!({content: message + event.title, from_user_id: uid})

        notify = notification.to_json(:except => [:user_id])
        socket_id = p
        unless settings.sockets[socket_id].nil?
          EM.next_tick { settings.sockets[socket_id].send(notify) }
        end
      }

      event.to_json(
          json: Event,
          methods: [:repeated_number],
          include: {participants: {only: :id}, team_participants: {only: :id}})
    end

    delete '/events/:eventId' do
      event = Event.find(params[:eventId])
      if @userid == event.creator_id
        uid = @userid

        event.participants.each { |p|
          user = User.find(p.id)

          if event.creator_id == p.id
            content = 'You have canceled the event ' + event.title
          else
            content = 'Has canceled the event ' + event.title
          end

          user.dashboard_records.create!({content: content, from_user_id: uid})
          notification = user.notifications.create!({content: content, from_user_id: uid})
          notify = notification.to_json(:except => uid)
          socket_id = p.id
          unless settings.sockets[socket_id].nil?
            EM.next_tick { settings.sockets[socket_id].send(notify) }
          end
        }

        event.destroy
        200
      else
        403
      end
    end
  end
end