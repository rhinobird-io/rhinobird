class UpdateCalendarEventChangeType < ActiveRecord::Migration
  def change
    change_column :events, :repeated_end_type, :string
  end
end
