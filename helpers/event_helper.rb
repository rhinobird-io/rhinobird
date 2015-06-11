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
    num.times do
      evt = pq.pop
      if evt.nil?
        return result
      else
        if min_datetime.nil? or min_datetime < evt.from_time
          result << evt
          next_event = evt.get_next_occurrence
          unless next_event.nil?
            pq.push(next_event, next_event.from_time)
          end
        end

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
    num.times do
      evt = pq.pop
      if evt.nil?
        return result
      else
        if max_datetime.nil? or max_datetime > evt.from_time
          result << evt
          previous_event = evt.get_previous_occurrence
          unless previous_event.nil?
            pq.push(previous_event, previous_event.from_time)
          end
        end
      end
    end
    result
  end
end