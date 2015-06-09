class Monthly < Repeated
  validates :repeated_by, inclusion: {in: %w(Month Week)}

  def occurrence(date, direction)
    from_time = self.from_time
    gap = DateHelper.month_diff(date, from_time)
    quotient = direction >= 0 ? [gap.fdiv(self.repeated_frequency).ceil, 0].max : [gap.fdiv(self.repeated_frequency).floor, 0].min
    if self.repeated_by == 'Month'    # Monthly repeat by day of month
      if direction >= 0 && gap >= 0 and date.day > from_time.day and gap % self.repeated_frequency == 0
        quotient += 1
      elsif direction < 0 && gap <= 0 and date.day < from_time.day and gap % self.repeated_frequency == 0
        quotient -= 1
      end
      from_time >> (quotient * self.repeated_frequency)
    elsif self.repeated_by == 'Week'  # Monthly repeat by day of week
      wday = from_time.wday
      weekdays = from_time.week_split.map{|d| d[wday]}.compact
      idx = weekdays.find_index{|d| d == from_time.day}
      current_weekdays = (from_time >> (quotient * self.repeated_frequency)).week_split.map{|d| d[wday]}.compact
      target_day = current_weekdays[idx] || current_weekdays.last
      if gap >= 0 and gap % self.repeated_frequency == 0 and target_day < date.day
        quotient += 1
        current_weekdays = (from_time >> (quotient * self.repeated_frequency)).week_split.map{|d| d[wday]}.compact
        target_day = current_weekdays[idx] || current_weekdays.last
      end
      (from_time >> (quotient * self.repeated_frequency)).change({day: target_day})
    else
      raise "Unexpected repeated_by #{self.repeated_by}"
    end
  end

  def next_occurrence(date)
    occurrence(date, 1)
  end

  def previous_occurrence(date)
    occurrence(date, -1)
  end

  def last_occurrence_by_times
    get_occurrence(self.repeated_times)
  end

  def get_occurrence(number)
    from_time = self.from_time
    repeated_number = self.repeated_number.nil? ? 1 : self.repeated_number
    if self.repeated_by == 'Month'
      from_time >> ((number - repeated_number) * self.repeated_frequency)
    elsif self.repeated_by == 'Week'  # Monthly repeat by day of week
      wday = from_time.wday
      weekdays = from_time.week_split.map{|d| d[wday]}.compact
      idx = weekdays.find_index{|d| d == from_time.day}
      current_weekdays = (from_time >> ((number - repeated_number) * self.repeated_frequency)).week_split.map{|d| d[wday]}.compact
      target_day = current_weekdays[idx] || current_weekdays.last
      (from_time >> ((number - repeated_number) * self.repeated_frequency)).change({day: target_day})
    end
  end
end