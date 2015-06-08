class Yearly < Repeated
  def next_occurrence(date)
    from_time = self.from_time
    gap = date.year - from_time.year
    quotient = [gap.fdiv(self.repeated_frequency).ceil, 0].max
    if gap >= 0 and gap % self.repeated_frequency == 0 and (date.month > from_time.month or (date.month == from_time.month and date.day > from_time.day))
      quotient += 1
    end
    from_time + (quotient * self.repeated_frequency).years
  end

  def last_occurrence_by_times
    self.from_time + ((self.repeated_times - 1) * self.repeated_frequency).years
  end

end