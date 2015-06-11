class Yearly < Repeated
  def occurrence(date, direction)
    from_time = self.from_time
    gap = date.year - from_time.year
    quotient = direction >= 0 ? [gap.fdiv(self.repeated_frequency).ceil, 0].max : [gap.fdiv(self.repeated_frequency).floor, 0].min
    if direction >= 0 and gap >= 0 and gap % self.repeated_frequency == 0 and (date.month > from_time.month or (date.month == from_time.month and date.day > from_time.day))
      quotient += 1
    elsif direction < 0 and gap <= 0 and gap % self.repeated_frequency == 0 and (date.month < from_time.month or (date.month == from_time.month and date.day < from_time.day))
      quotient -= 1
    end
    from_time + (quotient * self.repeated_frequency).years
  end

  def next_occurrence(date)
    occurrence(date, 1)
  end

  def previous_occurrence(date)
    occurrence(date, -1)
  end

  def last_occurrence_by_times
    self.get_occurrence(self.repeated_times)
  end

  def get_occurrence(number)
    repeated_number = self.repeated_number.nil? ? 1 : self.repeated_number
    self.from_time + ((number - repeated_number) * self.repeated_frequency).years
  end
end