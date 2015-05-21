
class DateHelper
  # Calculate the day difference of two dates(date_1 - date_2)
  def self.day_diff(date_1, date_2)
    date_1.mjd - date_2.mjd
  end

  # Calculate the month difference of two dates(date_1 - date_2)
  def self.month_diff(date_1, date_2)
    (date_1.year * 12 + date_1.month) - (date_2.year * 12 + date_2.month)
  end

  # Calculate the week difference of two dates(date_1 - date_2)
  def self.week_diff(date_1, date_2)
    day_diff = day_diff(date_1, date_2)
    if date_1.wday < date_2.wday
      day_diff / 7 + 1
    else
      day_diff / 7
    end
  end

  # Calculate the year difference of two dates(date_1 - date_2)
  def self.year_diff(date_1, date_2)
    date_1.year - date_2.year
  end


  # Return the number of week day of a date in is month
  # E.g: 2015/1/1 is the first Thursday of January, then this method will return 1
  def self.week_day_of_month(date)
    day = date.day
    result = 1
    while day - 7 >= 0 do
      result = result + 1
      day -= 7
    end
    return result
  end
end