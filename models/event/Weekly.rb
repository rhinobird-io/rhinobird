class Weekly < Repeated
  validates :repeated_on, presence: true

  def occurrence(date, direction)
    from_time = self.from_time
    gap = date.beginning_of_week - from_time.to_date.beginning_of_week
    quotient = direction >= 0 ? [gap.fdiv(self.repeated_frequency * 7).ceil, 0].max : [gap.fdiv(self.repeated_frequency * 7).floor, 0].min
    wday_hash = {'Sun' => 0, 'Mon' => 1, 'Tue' => 2, 'Wed' => 3, 'Thu' => 4, 'Fri' => 5, 'Sat' => 6}
    repeated_on = JSON.parse(self.repeated_on).map{|r| wday_hash[r]}

    if direction >= 0
      if gap < 0
        day = repeated_on.find {|d| d >= from_time.wday}
      elsif quotient == 0
        day = repeated_on.find {|d| d >= [date.wday, from_time.wday].max}
      else
        day = repeated_on.find {|d| d >= date.wday}
      end
    else
      if gap > 0
        day = repeated_on.find {|d| d <= from_time.wday}
      elsif quotient == 0
        day = repeated_on.find {|d| d <= [date.wday, from_time.wday].min}
      else
        day = repeated_on.find {|d| d <= date.wday}
      end
    end

    gap = 0
    if day.nil?
      if direction >= 0
        day = repeated_on.first
        gap += 7 * self.repeated_frequency
      else
        day = repeated_on.last
        gap -= 7 * self.repeated_frequency
      end
    end
    gap += day - from_time.wday
    from_time + (quotient * self.repeated_frequency * 7 + gap).days
  end

  def previous_occurrence(date)
    occurrence(date, -1)
  end

  def next_occurrence(date)
    occurrence(date, 1)
  end

  def last_occurrence_by_times
    self.get_repeated_event(self.repeated_times).from_time.to_date
  end

  def get_occurrence(number)
    event = self.get_repeated_event(number)
    event.nil? ? nil : event.from_time.to_date
  end
end