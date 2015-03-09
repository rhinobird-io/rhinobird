class UpdateCalendarEventSupportRepeatEvent < ActiveRecord::Migration
  def change
    add_column :events, :repeated, :boolean, :default => false
    add_column :events, :repeated_type, :string
    add_column :events, :repeated_frequency, :integer
    add_column :events, :repeated_on, :string
    add_column :events, :repeated_by, :string
    add_column :events, :repeated_times, :integer
    add_column :events, :repeated_end_type, :integer
    add_column :events, :repeated_end_date, :datetime
  end
end
