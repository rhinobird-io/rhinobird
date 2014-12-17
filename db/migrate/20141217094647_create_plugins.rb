class CreatePlugins < ActiveRecord::Migration
  def change
    create_table :plugins do |t|
      t.string :name, :unique
      t.text :description

      t.timestamps
    end
  end
end
