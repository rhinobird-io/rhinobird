class Weekly < Repeated
  validates :repeated_on, presence: true

  def occurrence1(date, direction)
    if direction >= 0
      if date < self.from_time.to_date
        return self.from_time
      end
    else
      if date > self.from_time.to_date
        return self.from_time
      end
    end
    from_time = self.from_time
    from_date = from_time.to_date
    week_diff = DateHelper.week_diff(date, from_date)
    week_diff_abs = week_diff.abs

    # Get the repeated days hash
    wday_hash = {'Sun' => 0, 'Mon' => 1, 'Tue' => 2, 'Wed' => 3, 'Thu' => 4, 'Fri' => 5, 'Sat' => 6}

    repeated_on = JSON.parse(self.repeated_on).map{|r| wday_hash[r]}

    day_diff = date - from_date
    self_wday = from_date.wday
    other_wday = date.wday
    quotient = week_diff_abs.fdiv(self.repeated_frequency).floor
    remainder = week_diff_abs - quotient * self.repeated_frequency
    if remainder == 0
      if direction >= 0
        day = repeated_on.find { |d| d >= other_wday}
      else
        day = repeated_on.find { |d| d >= self_wday}
      end
    else
      if direction >= 0
        day = repeated_on.first
        day_diff += (self.repeated_frequency - remainder) * 7 + day - other_wday
      else
        day = repeated_on.last
        day_diff -= (self.repeated_frequency - remainder) * 7 + other_wday - day
      end
    end

    if day.nil?
      if direction >= 0
        day = repeated_on.first
      else
        day = repeated_on.last
      end
    end

    if direction >= 0
      day_diff += (self.repeated_frequency - remainder) * 7 + day - other_wday
    else
      day_diff -= (self.repeated_frequency - remainder) * 7 + other_wday - day
    end

    from_time + day_diff
  end

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
        day = repeated_on.reverse.find {|d| d <= from_time.wday}
      elsif quotient == 0
        day = repeated_on.reverse.find {|d| d <= [date.wday, from_time.wday].min}
      else
        day = repeated_on.reverse.find {|d| d <= date.wday}
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

    if direction >= 0
      gap += day - from_time.wday
    else
      gap -= from_time.wday - day
    end

    puts "From Time: #{from_time}"
    puts "Quotient: #{quotient}"
    puts "Gap: #{gap}"
    puts "Day: #{day}"
    from_time + (quotient * self.repeated_frequency * 7 + gap).days
  end

  def previous_occurrence(date)
    puts "Date: #{date}"
    occurrence(date, -1)
  end

  def next_occurrence(date)
    occurrence(date, 1)
  end

  def last_occurrence_by_times
    self.get_occurrence(self.repeated_times)
  end

  def get_occurrence(number)

    from_time = self.from_time
    from_date = from_time.to_date
    repeated_number = self.repeated_number.nil? ? 1 : self.repeated_number

    wday_hash = {'Sun' => 0, 'Mon' => 1, 'Tue' => 2, 'Wed' => 3, 'Thu' => 4, 'Fri' => 5, 'Sat' => 6}

    wday_repeat = Array.new(7, false)
    repeated_on = JSON.parse(self.repeated_on)

    repeated_on_count = 0
    repeated_on.each {|r|
      wday_repeat[wday_hash[r]] = true
      repeated_on_count += 1
    }

    day_diff = 0
    wday = from_date.wday
    if number == repeated_number
      day_diff = 0
    elsif number > repeated_number
      gap = number - repeated_number
      ((wday + 1)..6).each{ |w|
        if wday_repeat[w] && gap > 0
          gap -= 1
          day_diff = w - wday
        end
      }
      if gap > 0
        day_diff = 6 - wday

        quotient = gap.fdiv(repeated_on_count).floor
        remainder = gap - quotient * repeated_on_count

        day_diff += quotient * self.repeated_frequency * 7 - 7

        remain_days = 0
        if remainder == 0
          remainder = repeated_on_count
        else
          day_diff += self.repeated_frequency * 7
        end
        if remainder > 0
          wday_repeat.each_with_index { |w, index|
            if w && remainder > 0
              remainder -= 1
              remain_days = index + 1
            end
          }
        end
        day_diff += remain_days
      end
    else
      gap = repeated_number - number
      (0..(wday - 1)).each{ |w|
        if wday_repeat[w] && gap > 0
          gap -= 1
          day_diff = wday - w
        end
      }
      if gap > 0
        day_diff = wday

        quotient = gap.fdiv(repeated_on_count).floor
        remainder = gap - quotient * repeated_on_count

        day_diff += quotient * self.repeated_frequency * 7 - 7

        remain_days = 0
        if remainder == 0
          remainder = repeated_on_count
        else
          day_diff += self.repeated_frequency * 7
        end
        if remainder > 0
          6.downto(0).each { |i|
            if wday_repeat[i] and remainder > 0
              remainder -= 1
              remain_days = 6 - i + 1
            end
          }
        end

        day_diff += remain_days
        day_diff = -day_diff
      end

    end

    from_time + day_diff.days
  end
end