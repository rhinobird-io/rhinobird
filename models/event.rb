# require 'elasticsearch/model'

class Event < ActiveRecord::Base
  # include Elasticsearch::Model
  # include Elasticsearch::Model::Callbacks

  belongs_to :creator, class_name: :User
  has_many :appointments
  has_many :team_appointments
  has_many :participants, through: :appointments
  has_many :team_participants, through: :team_appointments
  attr_accessor :repeated_number, :integer

  # Get the $(repeated_number)th event of a repeated one
  def get_repeated_event(repeated_number)
    number = repeated_number.to_i
    puts "Repeated number: #{number} #{self.repeated_times}"

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
          puts days_in_week
          puts date.wday
          puts self.repeated_on.index(days_in_week[date.wday])
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

end

# Event.import