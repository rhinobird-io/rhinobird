class UpdateCalendarEventAddColumns < ActiveRecord::Migration
  def change
    add_column :events, :status, :integer, :default => 0
    add_column :events, :repeated_exclusion, :integer, array: true
  end
end
