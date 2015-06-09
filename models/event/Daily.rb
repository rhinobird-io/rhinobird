class Daily < Repeated
  def occurrence(date, direction)
    from_time = self.from_time
    gap = date - from_time.to_date
    quotient = direction < 0 ? [gap.fdiv(self.repeated_frequency).floor, 0].min : [gap.fdiv(self.repeated_frequency).ceil, 0].max
    from_time + (quotient * self.repeated_frequency).days
  end

  def previous_occurrence(date)
    self.occurrence(date, -1)
  end

  def next_occurrence(date)
    self.occurrence(date, 1)
  end

  def get_occurrence(number)
    repeated_number = self.repeated_number.nil? ? 1 : self.repeated_number
    if number <= 0
      nil
    else
      self.from_time + ((number - repeated_number) * self.repeated_frequency).days
    end
  end

  def last_occurrence_by_times
    repeated_number = self.repeated_number.nil? ? 1 : self.repeated_number
    self.from_time + ((self.repeated_times - repeated_number) * self.repeated_frequency).days
  end
end