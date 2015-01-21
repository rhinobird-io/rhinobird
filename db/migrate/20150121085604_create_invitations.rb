class CreateInvitations < ActiveRecord::Migration
  def change
    create_table :invitations do |t|
      t.string :email
      t.integer :from_user_id
      t.integer :initial_team_id
      t.timestamps
    end
  end
end
