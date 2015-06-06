class Daily < Repeated

  def next_occurrence(date)
    from_time = self.from_time
    gap = date - from_time.to_date
    quotient = gap.fdiv(self.repeated_frequency).ceil
    from_time + (quotient * self.repeated_frequency).days
  end

  def last_occurrence_by_times
    self.from_time + ((self.repeated_times - 1) * self.repeated_frequency).days
  end

end