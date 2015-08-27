require 'algorithms'

module EventHelper
  def self.next_n_events(events, date, num, min_datetime = nil)
    result = []
    pq = Containers::PriorityQueue.new{ |x, y| (x <=> y) == -1 }
    events.each do |evt|
      next_event = evt.get_next_event(date)
      unless next_event.nil?
        pq.push(next_event, next_event.from_time)
      end
    end

    count = 0
    until pq.empty? do
      evt = pq.pop
      if evt.nil?
        return result
      else
        if min_datetime.nil? or evt.from_time > min_datetime
          count += 1
          result << evt
        end

        next_event = evt.get_next_occurrence
        unless next_event.nil?
          pq.push(next_event, next_event.from_time)
        end
      end
      if count >= num
        break
      end
    end
    result
  end

  def self.previous_n_events(events, date, num, max_datetime = nil)
    result = []
    pq = Containers::PriorityQueue.new{ |x, y| (x <=> y) == 1 }
    events.each do |evt|
      previous_event = evt.get_previous_event(date)
      unless previous_event.nil?
        pq.push(previous_event, previous_event.from_time)
      end
    end

    count = 0
    until pq.empty? do
      evt = pq.pop
      if evt.nil?
        return result
      else
        if max_datetime.nil? or max_datetime > evt.from_time
          count += 1
          puts evt.from_time
          result << evt
        end

        previous_event = evt.get_previous_occurrence
        unless previous_event.nil?
          pq.push(previous_event, previous_event.from_time)
        end
      end
      if count >= num
        break
      end
    end
    puts result
    result
  end

  # Get all events of one day
  def self.get_events_by_date(events, date)
    EventHelper.get_events_by_dates(events, [].push(date))
  end

  # Get all events of several days
  def self.get_events_by_dates(events, dates)
    result = []
    events.each do |evt|
      dates.each do |date|
        if !evt.repeated
          if date == evt.from_time.to_date
            result.push(evt)
            break
          end
        else
          repeated_number = evt.get_repeated_number(date)
          if repeated_number >= 1
            result.push(evt.get_event_by_repeated_number(repeated_number))
          end
        end
      end
    end
    result
  end

  # Get all the events of one week
  def self.get_events_by_week(events, date)
    weekdays = []
    (0..6).each{|i| weekdays.push(date + i - date.wday)}
    EventHelper.get_events_by_dates(events, weekdays)
  end

  # Get all the events of four days starting from the date
  def self.get_events_by_four_days(events, date)
    weekdays = []
    (0..3).each{|i| weekdays.push(date + i)}
    EventHelper.get_events_by_dates(events, weekdays)
  end

  def self.get_events_by_month(events, date)
    month_days = []
    month = date.month
    (0..31).each{|i|
      day = date + i - date.day
      if month == day.month
        month_days.push(day)
      end
    }
    EventHelper.get_events_by_dates(events, month_days)
  end

  def self.get_events_by_calendar_month(events, date)
    calendar_month_days = []
    month = date.month
    first_month_day = date - date.day + 1
    last_month_day = first_month_day
    (0..(first_month_day.wday - 1)).each{|d|
      day = first_month_day + d - first_month_day.wday
      calendar_month_days.push(day)
    }
    (0..32).each{|i|
      day = first_month_day + i
      if month == day.month
        calendar_month_days.push(day)
      else
        last_month_day = day - 1
        break
      end
    }
    ((last_month_day.wday + 1)..6).each{|d|
      day = last_month_day + d - last_month_day.wday
      calendar_month_days.push(day)
    }
    EventHelper.get_events_by_dates(events, calendar_month_days)
  end
end