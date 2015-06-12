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
end