# encoding: utf-8
class App < Sinatra::Base
  namespace '/api' do

    # Calculate the day difference of two dates(date_1 - date_2)
    def day_diff(date_1, date_2)
      return date_1.mjd - date_2.mjd
    end

    # Calculate the month difference of two dates(date_1 - date_2)
    def month_diff(date_1, date_2)
      (date1.year * 12 + date_1.month) - (date_2.year * 12 + date_2.month)
    end

    # Calculate the week difference of two dates(date_1 - date_2)
    def week_diff(date_1, date_2)
      day_diff = day_diff(date_1, date_2)
      if date_1.wday < date_2.wday
        return day_diff / 7 + 1
      else
        return day_diff / 7
      end
    end

    # Return the number of week day of a date in is month
    # E.g: 2015/1/1 is the first Thursday of January, then this method will return 1
    def week_day_of_month(date)
      day = date.day
      result = 1
      while day - 7 >= 0 do
        result = result + 1
        day -= 7
      end
      return result
    end

    # Calculate the year difference of two dates(date_1 - date_2)
    def year_diff(date_1, date_2)
      date_1.year - date_2.year
    end

    # Return the first copy of repeated event which will happen after $datetime
    # If there's no such copy, return nil
    def first_occur_repeated_event_after(event, datetime)
      nil
    end

    # Check whether the events will happen on certain date
    # True, than return the repeated number
    # Otherwise, return 0
    def get_repeated_number(event, date)
      from_date = event.from_time.to_date

      if !event.repeated
        date == from_date
      else
        # When the event is repeated
        if date < from_date
          return 0
        elsif date == from_date
          return 1
        end

        # 1. The date should not exceed the end date of the repeated event
        # If event's event type is to end on certain date
        if event.repeated_end_type == 'Date'
          if event.repeated_end_date < date
            return 0
          end
        end

        # Days, weeks, months or years after the repeat event's start datetime
        range_after = 0

        # 2. The date should match the repeated type's corresponding date
        daysInWeek = %w(Sun Mon Tue Wed Thu Fri Sat)
        case event.repeated_type
          when 'Daily'
            range_after = day_diff(date, from_date)
          when 'Weekly'
            # If the week day's of date is not within the repeated setting, return false
            puts daysInWeek
            puts date.wday
            puts event.repeated_on.index(daysInWeek[date.wday])
            if event.repeated_on.index(daysInWeek[date.wday]).nil?
              return 0
            end
            range_after = week_diff(date, from_date)
          when 'Monthly'
            if event.repeated_by == 'Month'
              # When monthly repeated by day of month
              # If the day of month is not equal, return false
              if date.day != from_date.day
                return 0
              end
            elsif event.repeated_by == 'Week' # E.g: both are the second Monday
              # When monthly repeated by day of month
              # If the day of week is not equal, return false
              unless date.wday == from_date.wday && week_day_of_month(date) == week_day_of_month(from_date)
                return 0
              end
            end
            range_after = month_diff(date, from_date)
          when 'Yearly'
            # If not the same day of years, return false
            unless date.month == from_date.month && date.day == from_date.day
              return 0
            end
            range_after = year_diff(date, from_date)
        end

        # 3. The date should match the repeated frequency
        # If the date won't match the repeat frequency
        if range_after % event.repeated_frequency != 0
          return 0
        end

        # The repeated number of the repeated event
        repeated_number = range_after / event.repeated_frequency + 1

        # 4. The repeated number should not exceed the setted repeated times
        # If repeat event will end after certain times
        if event.repeated_end_type == 'Occurence'
          if repeated_number > event.repeated_times
            return 0
          end
        end

        repeated_number
      end
    end

    # Get the $(repeated_number)th event of a repeated one
    def get_repeated_event(event, repeated_number)
      if event.nil? or !event.repeated
        event
      else
        event.repeated_number = repeated_number
        event
      end
    end

    get '/events' do
      today = Date.today

      user = User.find(@userid)

      all_events = Array.new
      all_events.concat user.events

      user.teams.each { |t|
        all_events.concat t.events
      }

      repeated_events_on_today = Array.new
      today_or_after_events = Array.new
      old_events = Array.new

      all_events.each { |e|
        e.repeated_number = 1

        repeated_number = get_repeated_number(e, today)
        if e.repeated && e.from_time.to_date != today && repeated_number > 0
          day_diff = day_diff(today, e.from_time.to_date)
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
      events.concat User.find(@userid).events.where("from_time > ?", from)

      User.find(@userid).teams.each { |t|
        events.concat t.events.where("from_time > ?", from)
      }

      results = Array.new
      events.each { |e|
        e.repeated_number = 1
      }

      results.sort! { |a, b| a.from_time <=> b.from_time }.
          first(5).
          to_json(
            json: Event,
            methods: [:repeated_number],
            include: {participants: {only: :id}, team_participants: {only: :id}})
    end

    get '/events/before/:from_time' do
      from = DateTime.parse(params[:from_time])

      events = Array.new
      events.concat User.find(@userid).events.where("from_time < ?", from)

      User.find(@userid).teams.each { |t|
        events.concat t.events.where("from_time < ?", from)
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

    get '/events/:eventId/:repeatedNumber' do
      e = Event.find(params[:eventId])

      if e.nil?
        404
      else
        event = get_repeated_event(e, params[:repeatedNumber])

        event.to_json(
            json: Event,
            methods: [:repeated_number],
            include: {participants: {only: :id}, team_participants: {only: :id}})
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
          if !notified_users.include? u.id
            notified_users << u.id
          end
        }
      }

      @body['participants']['users'].each { |p|
        user = User.find(p)
        if !notified_users.include? user.id
          notified_users << user.id
          event.participants << user
        end
      }

      # Whether the event creator is also a participant by default?
      user_self = User.find(uid)
      if !notified_users.include? uid
        event.participants << user_self
        notified_users << uid
      end
      event.creator_id = uid

      event.save!

      notified_users.each { |p|
        user = User.find(p)

        message = ''
        if event.creator_id == p
          message = 'You have created an event '
        else
          message = 'Invited you to the event '
        end
        user.dashboard_records.create!({
                                           content: message,
                                           from_user_id: uid,
                                           has_link: true,
                                           link_url: '#/calendar/' + event.id.to_s,
                                           link_title: event.title})

        notification = user.notifications.create!({content: message + event.title, from_user_id: uid})

        notify = notification.to_json(:except => [:user_id])
        socket_id = p
        unless settings.sockets[socket_id].nil?
          EM.next_tick { settings.sockets[socket_id].send(notify) }
        end
      }

      event.to_json(include: {participants: {only: :id}, team_participants: {only: :id}})
    end

    delete '/events/:eventId' do
      event = Event.find(params[:eventId])
      if @userid == event.creator_id
        uid = @userid

        event.participants.each { |p|
          user = User.find(p.id)

          content = ''
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