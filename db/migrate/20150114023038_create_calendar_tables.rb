class CreateCalendarTables < ActiveRecord::Migration
  def change

    create_table :appointments do |t|
      t.belongs_to :event, index: true
      t.belongs_to :participant, index: true
    end

    create_table :events do |t|
      t.string :title
      t.boolean :full_day
      t.boolean :period
      t.timestamp :from
      t.timestamp :to
      t.text :description
      t.timestamps
      t.belongs_to :creator, index: true
    end
  end
end
