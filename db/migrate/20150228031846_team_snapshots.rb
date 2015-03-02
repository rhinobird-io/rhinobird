class TeamSnapshots < ActiveRecord::Migration
  def change
    create_table :team_snapshots do |t|
      t.string :type, null: false
      t.integer :member_user_id
      t.integer :member_team_id

      t.timestamps
    end
  end
end
