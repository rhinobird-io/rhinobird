class Monthly < Repeated

  def next_occurrence(date)
    from_time = self.from_time
    gap = month_diff(date, from_time)
    quotient = gap.fdiv(self.repeated_frequency).ceil
    if self.repeated_by == 'Month'    # Monthly repeat by day of month
      if date.day > from_time.day
        quotient += 1
      end
      from_time >> (quotient * self.repeated_frequency)
    elsif self.repeated_by == 'Week'  # Monthly repeat by day of week
      wday = from_time.wday
      weekdays = from_time.week_split.map{|d| d[wday]}.compact
      idx = weekdays.find_index{|d| d == from_time.day}
      current_weekdays = (from_time >> (quotient * self.repeated_frequency)).week_split.map{|d| d[wday]}.compact
      target_day = current_weekdays[idx] || current_weekdays.last
      if target_day.to_date > date.to_date
        quotient += 1
      end
      current_weekdays = (from_time >> (quotient * self.repeated_frequency)).week_split.map{|d| d[wday]}.compact
      target_day = current_weekdays[idx] || current_weekdays.last
      from_time >> (quotient * self.repeated_frequency).change({day: target_day})
    else
      raise 'Unexpected repeated_by'
    end
  end

  def last_occurrence_by_times
    from_time = self.from_time
    if self.repeated_by == 'Month'
      from_time >> ((self.repeated_times - 1) * self.repeated_frequency)
    elsif self.repeated_by == 'Week'  # Monthly repeat by day of week
      wday = from_time.wday
      weekdays = from_time.week_split.map{|d| d[wday]}.compact
      idx = weekdays.find_index{|d| d == from_time.day}
      current_weekdays = (from_time >> ((self.repeated_times - 1) * self.repeated_frequency)).week_split.map{|d| d[wday]}.compact
      current_weekdays[idx] || current_weekdays.last
    end
  end


end