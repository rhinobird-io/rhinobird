class UpdateCalendarEventChangeColumn < ActiveRecord::Migration
  def change
    change_column :events, :repeated_exclusion, :text
  end
end
