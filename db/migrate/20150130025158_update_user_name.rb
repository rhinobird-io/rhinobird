class UpdateUserName < ActiveRecord::Migration
  def change
    add_column :users, :name, :string
    add_index :users, :name, unique: true
    add_index :users, :email, unique: true
  end
end
