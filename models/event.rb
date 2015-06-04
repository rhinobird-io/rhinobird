# require 'elasticsearch/model'

class Event < ActiveRecord::Base
  # include Elasticsearch::Model
  # include Elasticsearch::Model::Callbacks

  enum status:  { created: 0, trashed: 1 }

  serialize :repeated_exclusion, Array

  belongs_to :creator, class_name: :User
  has_many :appointments
  has_many :team_appointments
  has_many :participants, through: :appointments
  has_many :team_participants, through: :team_appointments
  attr_accessor :repeated_number, :integer

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
      to_time = self.to_time

      range = 0
      case self.repeated_type
        when 'Daily'
          range = (repeated_frequency * (number - 1)).day
        when 'Weekly'

        when 'Monthly'
          range = (repeated_frequency * (number - 1)).month

          # TODO: consider the repeated by week of month
        when 'Yearly'
          range = (repeated_frequency * (number - 1)).year
        else
          # type code here
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
  # True, than return the repeated number
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
        if self.repeated_end_date < date
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
      elsif repeated_end_type == 'Date'
        summary += ", until #{repeated_end_date.to_date}"
      end

      summary
    else
      'No Repeat'
    end
  end
end

# Event.import