class CreateDashboard < ActiveRecord::Migration
  def change
    create_table :dashboard_records do |t|
      t.belongs_to :user, index: true
      t.text :content, null: false
      t.timestamps
    end
  end
end
