class AddColumnToPlugins < ActiveRecord::Migration
  def change
  	add_column :plugins, :author, :string
  	add_column :plugins, :url, :string
  end
end
