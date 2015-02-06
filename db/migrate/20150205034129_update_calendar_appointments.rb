class UpdateCalendarAppointments < ActiveRecord::Migration
  def change
    add_column :appointments, :participant_type, :string
  end
end
