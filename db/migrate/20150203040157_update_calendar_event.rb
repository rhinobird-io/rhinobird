class UpdateCalendarEvent < ActiveRecord::Migration
  def change
    remove_column :events, :from
    remove_column :events, :to
    add_column :events, :fromTime, :timestamp
    add_column :events, :toTime, :timestamp
  end
end
