class CreateTeams < ActiveRecord::Migration
  def change
    create_table :teams do |t|
      t.string :name

      t.timestamps
    end

    create_table :users_teams do |t|
      t.integer :user_id, null: false
      t.integer :team_id, null: false

      t.timestamps
    end

    add_index :users_teams, :user_id
  end
end