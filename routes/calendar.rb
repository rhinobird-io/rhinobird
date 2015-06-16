# encoding: utf-8

class App < Sinatra::Base

  namespace '/api' do
    get '/events' do
      today = Date.today

      user = User.find(@userid)
      all_events = user.get_all_not_trashed_events


      result = EventHelper.next_n_events(all_events, today, 10)

      puts "result #{result.length}"
      if result.length < 10
        result.concat EventHelper.previous_n_events(all_events, today - 1, 10 - result.length)
      end

      result.to_json(
          json: Event,
          methods: [:repeated_number, :repeated_type],
          include: {participants: {only: :id}, team_participants: {only: :id}}
      )
    end

    get '/events/after/:from_time' do
      from = DateTime.parse(params[:from_time])

      user = User.find(@userid)
      all_events = user.get_all_not_trashed_events
      result = EventHelper.next_n_events(all_events, from.to_date, 5, from)

      result.to_json(
            json: Event,
            methods: [:repeated_number],
            include: {participants: {only: :id}, team_participants: {only: :id}})
    end

    get '/events/before/:from_time' do
      from = DateTime.parse(params[:from_time])

      user = User.find(@userid)
      all_events = user.get_all_not_trashed_events

      result = EventHelper.previous_n_events(all_events, from.to_date, 5, from)

      result.sort! { |a, b| a.from_time <=> b.from_time }.
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
          event = e.get_event_by_repeated_number(params[:repeatedNumber].to_i)

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

      notified_users = {}

      @body['participants']['teams'].each { |p|
        team = Team.find(p)
        event.team_participants << team
        team.get_all_users.each { |u|
          if notified_users[u.id].nil?
            notified_users[u.id] = u.id
          end
        }
      }

      @body['participants']['users'].each do |p|
        user = User.find(p)
        if notified_users[user.id].nil?
          notified_users[user.id] = user.id
          event.participants << user
        end
      end

      user_self = User.find(uid)
      if notified_users[user_self.id].nil?
        notified_users[user_self.id] = user_self.id
        event.participants << user_self
      end

      event.creator_id = uid
      event.status = 'created'

      if event.repeated && event.repeated_type == 'Weekly' && event.repeated_end_type == 'Occurrence'
        event.repeated_times = 3 * event.repeated_times
      end

      event.save!

      ActiveRecord::Base.transaction do
        notified_users.values.each { |p|
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

          if event.creator_id != p
            notification = user.notifications.create!({content: message + event.title,
                                                       from_user_id: uid,
                                                       url: "/platform/calendar/events/#{event.id}/1"})

            notify = notification.to_json(:except => [:user_id])
            notify(
                user,
                notify,
                "[RhinoBird] #{user_self.realname} invited you to event #{event.title}",
                erb(:'email/event_created', locals: {creator: user_self, user: user, event: event}))
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

          if event.creator_id != p.id
            notification = user.notifications.create!({content: content, from_user_id: uid})
            notify = notification.to_json(:except => uid)
            socket_id = p.id
            unless settings.sockets[socket_id].nil?
              EM.next_tick { settings.sockets[socket_id].send(notify) }
            end
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
            event = event.get_event_by_repeated_number(repeated_number.to_i)
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