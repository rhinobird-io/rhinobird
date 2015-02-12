class CreateTeamAppointments < ActiveRecord::Migration
  def change
  	create_table :team_appointments do |t|
      t.belongs_to :event, index: true
      t.belongs_to :team_participant, index: true
    end
  end
end
