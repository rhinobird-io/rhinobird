class Weekly < Repeated
  validates :repeated_on, presence: true
  def next_occurrence(date)
    from_time = self.from_time
    gap = date.beginning_of_week - from_time.to_date.beginning_of_week
    quotient = [gap.fdiv(self.repeated_frequency * 7).ceil, 0].max
    wday_hash = {'Sun' => 0, 'Mon' => 1, 'Tue' => 2, 'Wed' => 3, 'Thu' => 4, 'Fri' => 5, 'Sat' => 6}
    repeated_on = JSON.parse(self.repeated_on).map{|r| wday_hash[r]}
    if gap < 0
      day = repeated_on.find {|d| d >= from_time.wday}
    elsif quotient == 0
      day = repeated_on.find {|d| d >= [date.wday, from_time.wday].max}
    else
      day = repeated_on.find {|d| d >= date.wday}
    end
    gap = 0
    if day.nil?
      day = repeated_on.first
      gap += 7 * self.repeated_frequency
    end
    gap += day - from_time.wday
    from_time + (quotient * self.repeated_frequency * 7 + gap).days
  end

  def last_occurrence_by_times
    self.from_time.to_date.end_of_week + ((self.repeated_times - 1) * self.repeated_frequency * 7).days
  end
end