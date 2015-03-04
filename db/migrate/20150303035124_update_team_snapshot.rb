class UpdateTeamSnapshot < ActiveRecord::Migration
  def change
    add_column :team_snapshots, :team_id, :integer
    rename_column :team_snapshots, :type, :event_type
  end
end
