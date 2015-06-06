# require 'elasticsearch/model'

class Event < ActiveRecord::Base
  # include Elasticsearch::Model
  # include Elasticsearch::Model::Callbacks

  self.inheritance_column = 'repeated_type'

  enum status:  { created: 0, trashed: 1 }

  serialize :repeated_exclusion, Array

  belongs_to :creator, class_name: :User
  has_many :appointments
  has_many :team_appointments
  has_many :participants, through: :appointments
  has_many :team_participants, through: :team_appointments
  attr_accessor :repeated_number
  validates :repeated_type, inclusion: {in: %w(Daily Weekly Monthly Yearly), allow_nil: true}
  validates :repeated_by, inclusion: {in: %w(Month Week), allow_nil: true}

  def participants_summary
    self.participants.map{|p| p.realname} + self.team_participants.map{|p| p.name}
  end

  def time_summary
    if self.period?
      if self.full_day?
        return "from #{self.from_time.strftime('%F')} to #{self.to_time.strftime('%F')}"
      else
        return "from #{self.from_time.strftime('%c')} to #{self.to_time.strftime('%c')}"
      end
    else
      if self.full_day?
        return self.from_time.strftime('%F')
      else
        return self.from_time.strftime('%c')
      end
    end
  end

  # def next_occurrence(date)
  #   from_time = self.from_time
  #   repeated_end_type = self.repeated_end_type
  #   case self.repeated_type
  #     when 'Daily'
  #       gap = date - from_time.to_date
  #       quotient, modulus = gap.divmod(self.repeated_frequency)
  #       quotient += 1 if modulus > 0
  #       if repeated_end_type == 'Occurrence' and quotient + 1 > self.repeated_times
  #         return nil
  #       end
  #       result = from_time + (quotient * self.repeated_frequency).days
  #       if repeated_end_type == 'Date' and result.to_date > self.repeated_end_date.to_date
  #         return nil
  #       end
  #       return result
  #     when 'Weekly'
  #       gap = date.beginning_of_week.to_date - from_time.beginning_of_week.to_date
  #       quotient, modulus = gap.divmod(self.repeated_frequency * 7)
  #       quotient += 1 if modulus > 0
  #       if repeated_end_type == 'Occurrence' and quotient + 1 > self.repeated_times
  #         return nil
  #       end
  #       wday_hash = {'Sun' => 0, 'Mon' => 1, 'Tue' => 2, 'Wed' => 3, 'Thu' => 4, 'Fri' => 5, 'Sat' => 6}
  #       repeated_on = JSON.parse(self.repeated_on).map{|r| wday_hash[r]}
  #       day = repeated_on.find {|d| d >= date.wday}
  #       gap = 0
  #       if day.nil?
  #         if repeated_end_type == 'Occurrence' and quotient > self.repeated_times
  #           return nil
  #         end
  #         day = repeated_on.first
  #         gap += 7 * self.repeated_frequency
  #       end
  #       gap += day - from_time.wday
  #       result = from_time + (quotient * self.repeated_frequency * 7 + gap).days
  #       if repeated_end_type == 'Date' and result.to_date > self.repeated_end_date.to_date
  #         return nil
  #       end
  #       return result
  #     when 'Monthly'
  #       gap = month_diff(date, from_time)
  #       quotient, modulus = gap.divmod(self.repeated_frequency)
  #       quotient += 1 if modulus > 0
  #       if repeated_end_type == 'Occurrence' and quotient + 1 > self.repeated_times
  #         return nil
  #       end
  #       if self.repeated_by == 'Month'    # Monthly repeat by day of month
  #         if date.day > from_time.day
  #           if repeated_end_type == 'Occurrence' and quotient > self.repeated_times
  #             return nil
  #           end
  #           quotient += 1
  #         end
  #         result = from_time >> (quotient * self.repeated_frequency)
  #         if repeated_end_type == 'Date' and result.to_date > self.repeated_end_date.to_date
  #           return nil
  #         end
  #         return result
  #       elsif self.repeated_by == 'Week'  # Monthly repeat by day of week
  #         wday = from_time.wday
  #         weekdays = from_time.week_split.map{|d| d[wday]}.compact
  #         idx = weekdays.find_index{|d| d == from_time.day}
  #         current_weekdays = (from_time >> (quotient * self.repeated_frequency)).week_split.map{|d| d[wday]}.compact
  #         target_day = current_weekdays[idx] || current_weekdays.last
  #         if target_day.to_date > date.to_date
  #           if repeated_end_type == 'Occurrence' and quotient > self.repeated_times
  #             return nil
  #           end
  #           quotient += 1
  #         end
  #         current_weekdays = (from_time >> (quotient * self.repeated_frequency)).week_split.map{|d| d[wday]}.compact
  #         target_day = current_weekdays[idx] || current_weekdays.last
  #         result = from_time >> (quotient * self.repeated_frequency).change({day: target_day})
  #         if repeated_end_type == 'Date' and result.to_date > self.repeated_end_date.to_date
  #           return nil
  #         end
  #         return result
  #       else
  #         raise 'Unexpected repeated_by'
  #       end
  #     when 'Yearly'
  #       gap = year_diff(date, from_time)
  #       quotient, modulus = gap.divmod(self.repeated_frequency)
  #       quotient += 1 if modulus > 0
  #       if repeated_end_type == 'Occurrence' and quotient + 1 > self.repeated_times
  #         return nil
  #       end
  #       if date.month < from_time.month or (date.month == from_time.month && date.day < from_time.day)
  #         if repeated_end_type == 'Occurrence' and quotient > self.repeated_times
  #           return nil
  #         end
  #         quotient += 1
  #       end
  #       result = from_time + (quotient * self.repeated_frequency).years
  #       if repeated_end_type == 'Date' and result.to_date > self.repeated_end_date.to_date
  #         return nil
  #       end
  #       return result
  #   end
  # end

  def get_next_event(date)
    if !date.nil?
        if date <= self.from_time
          self.dup
        else
          nil
        end
    else
      nil
    end
  end

  # Get the $(repeated_number)th event of a repeated one
  def get_repeated_event(repeated_number)
    number = repeated_number.to_i

    if self.repeated && number > 0
      self.repeated_number = number

      repeated_end_type = self.repeated_end_type

      if repeated_end_type == 'Occurrence' && number > self.repeated_times
        return nil
      end

      repeated_frequency = self.repeated_frequency

      from_time = self.from_time
      from_date = from_time.to_date
      to_time = self.to_time

      range = 0
      case self.repeated_type
        when 'Daily'
          range = (repeated_frequency * (number - 1)).day
        when 'Weekly'
          wday_hash = {'Sun' => 0, 'Mon' => 1, 'Tue' => 2, 'Wed' => 3, 'Thu' => 4, 'Fri' => 5, 'Sat' => 6};
          repeated_on = JSON.parse(self.repeated_on)
          wday_repeat = Array.new(7, false)

          repeated_on.each {|r| wday_repeat[wday_hash[r]] = true}

          # Start day's week day
          wday = from_date.wday

          next_week_number = (number.to_f / repeated_on.length).ceil
          left_days = number - (next_week_number - 1) * repeated_on.length
          next_wday = wday

          ((wday)..(wday + 6)).each { |i|
            if left_days == 0
              break
            end
            if wday_repeat[i % 7]
              next_wday = i
              left_days -= 1
            end
          }

          range = (repeated_frequency * (next_week_number - 1)).week + (next_wday - wday).day
        when 'Monthly'
          if self.repeated_by == 'Month'    # Monthly repeat by day of month
            range = (repeated_frequency * (number - 1)).month
          elsif self.repeated_by == 'Week'  # Monthly repeat by day of week
            temp_from_date = from_date + (repeated_frequency * (number - 1)).month
            temp_month = temp_from_date.month

            week_of_month = from_date.week_of_month
            wday = from_time.wday

            temp_week_of_month = temp_from_date.week_of_month
            temp_wday = temp_from_date.wday

            temp_from_date -= (temp_week_of_month - week_of_month).week
            temp_from_date -= (temp_wday - wday).day

            # If month has less week than the repeated one, use the last week's day
            # Eg: the event tend to repeat at fifth Friday of one Month by every 1 month, however,
            # there's a month doesn't have the fifth Friday, in this case, it will use the last Friday.
            if temp_from_date.month > temp_month
              temp_from_date -= 1.week
            end
            range = (temp_from_date - from_date).day
          else
            return nil
          end
        when 'Yearly'
          range = (repeated_frequency * (number - 1)).year
        else  # Repeated type error, return nil
          nil
      end

      from_time += range
      to_time += range

      if repeated_end_type == 'Date' && from_time > self.repeated_end_date
        return nil
      end

      self.from_time = from_time
      self.to_time = to_time
      self
    else
      nil
    end
  end

  # Check whether the events will happen on certain date
  # If so, than return the repeated number
  # Otherwise, return 0
  def get_repeated_number(date)
    from_date = self.from_time.to_date

    if !self.repeated
      date == from_date
    else
      # When the event is repeated
      if date < from_date
        return 0
      elsif date == from_date
        return 1
      end

      # 1. The date should not exceed the end date of the repeated event
      # If event's event type is to end on certain date
      if self.repeated_end_type == 'Date'
        if !self.repeated_end_date.nil? && self.repeated_end_date < date
          return 0
        end
      end

      # Days, weeks, months or years after the repeat event's start datetime
      range_after = 0

      # 2. The date should match the repeated type's corresponding date
      days_in_week = %w(Sun Mon Tue Wed Thu Fri Sat)

      case self.repeated_type
        when 'Daily'
          range_after = DateHelper.day_diff(date, from_date)
        when 'Weekly'
          # If the week day's of date is not within the repeated setting, return false
          if self.repeated_on.index(days_in_week[date.wday]).nil?
            return 0
          end
          range_after = DateHelper.week_diff(date, from_date)
        when 'Monthly'
          if self.repeated_by == 'Month'
            # When monthly repeated by day of month
            # If the day of month is not equal, return false
            if date.day != from_date.day
              return 0
            end
          elsif self.repeated_by == 'Week' # E.g: both are the second Monday
            # When monthly repeated by day of month
            # If the day of week is not equal, return false
            unless date.wday == from_date.wday && DateHelper.week_day_of_month(date) == DateHelper.week_day_of_month(from_date)
              return 0
            end
          end
          range_after = DateHelper.month_diff(date, from_date)
        when 'Yearly'
          # If not the same day of years, return false
          unless date.month == from_date.month && date.day == from_date.day
            return 0
          end
          range_after = DateHelper.year_diff(date, from_date)
        else
          # type code here
      end

      # 3. The date should match the repeated frequency
      # If the date won't match the repeat frequency
      if range_after % self.repeated_frequency != 0
        return 0
      end

      # The repeated number of the repeated event
      repeated_number = range_after / self.repeated_frequency + 1

      # 4. The repeated number should not exceed the set repeated times
      # If repeat event will end after certain times
      if self.repeated_end_type == 'Occurrence'
        if repeated_number > self.repeated_times
          return 0
        end
      end

      repeated_number
    end
  end

  # Return a short summary for repeated events
  # If the event is not repeated, then return No Repeat
  def get_repeated_summary
    if self.repeated
      summary = ''
      repeated_frequency = self.repeated_frequency
      frequency_once = self.repeated_type;
      frequency_multiple = ''
      from_time = self.from_time
      repeated_on = JSON.parse(self.repeated_on)
      repeated_by = self.repeated_by
      repeated_end_type = self.repeated_end_type
      repeated_times = self.repeated_times
      repeated_end_date = self.repeated_end_date

      if self.repeated_type == 'Daily'
        frequency_multiple = 'days'
      elsif self.repeated_type == 'Weekly'
        frequency_multiple = 'weeks'
      elsif self.repeated_type == 'Monthly'
        frequency_multiple = 'months'
      elsif self.repeated_type == 'Yearly'
        frequency_multiple = 'years'
      end

      # Repeat event frequency summary
      if repeated_frequency > 1
        summary += frequency_once
      else
        summary += "Every #{repeated_frequency} #{frequency_multiple}";
      end

      # Repeat event days summary
      if repeated_type == 'Weekly'
        summary += ' on '
        repeated_on.each_with_index { |item, index|
          summary += item
          unless index == repeated_on.length - 1
            summary += ', '
          end
        }
      elsif repeated_type == 'Monthly'
        summary += ' on '
        if repeated_by == 'Month'
          summary += " day #{from_time.to_date.day}"
        elsif repeated_by == 'Week'
          summary += " the #{from_time.to_date.week_of_month_in_eng.downcase} #{Date::DAYNAMES[from_time.to_date.wday]}";
        end
      elsif repeated_type == 'Yearly'
        summary += " on #{Date::MONTHNAMES[from_time.to_date.month]} #{from_time.to_date.day} "
      end

      # Repeated ends way
      if repeated_end_type == 'Occurrence'
        summary += ", #{repeated_times} times"
      elsif repeated_end_type == 'Date' && !repeated_end_date.nil?
        summary += ", until #{repeated_end_date.to_date}"
      end

      summary
    else
      'No Repeat'
    end
  end

  def <(other)
    self.from_time < other.from_time
  end

  def >(other)
    self.from_time > other.from_time
  end
end

class Repeated < Event
  after_initialize :init

  def init
    self.repeated = true
  end



  def available_occurrence?(time)
    last_occurrence = self.last_occurrence
    if last_occurrence.nil?
      return true
    end
    last_occurrence.to_date >= time.to_date
  end

  def last_occurrence
    if self.repeated_end_type == 'Occurrence'
      self.last_occurrence_by_times
    else
      self.repeated_end_date
    end
  end

  def get_next_event(date)
    from_time = self.from_time
    next_occurrence = self.next_occurrence(date)
    if next_occurrence.nil? or !self.available_occurrence?(next_occurrence)
      nil
    else
      gap = next_occurrence - from_time
      result = self.dup
      result.from_time += gap
      result.to_time += gap unless result.to_time.nil?
      result
    end
  end
end

# Event.import