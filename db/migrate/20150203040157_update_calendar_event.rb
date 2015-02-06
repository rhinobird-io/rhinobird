class UpdateCalendarEvent < ActiveRecord::Migration
  def change
    remove_column :events, :from
    remove_column :events, :to
    add_column :events, :from_time, :timestamp
    add_column :events, :to_time, :timestamp
  end
end
