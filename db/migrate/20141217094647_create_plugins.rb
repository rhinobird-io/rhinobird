class CreatePlugins < ActiveRecord::Migration
  def change
    create_table :plugins do |t|
      t.string :name
      t.text :description

      t.timestamps
    end
    add_index :plugins, :name, :unique => true
  end
end
