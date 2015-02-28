class TeamsRelations < ActiveRecord::Migration
  def change
    create_table :teams_relations do |t|
      t.integer :parent_team_id, null: false
      t.integer :team_id, null: false
    end
  end
end
