class CreateNotifications < ActiveRecord::Migration
  def change
    create_table :notifications do |t|
      t.belongs_to :user, index: true
      t.text :content, null: false
      t.integer :from_user_id, null: false
      t.timestamps
    end
  end
end
