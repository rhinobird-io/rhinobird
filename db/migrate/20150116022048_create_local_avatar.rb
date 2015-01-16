class CreateLocalAvatar < ActiveRecord::Migration
  def change
    create_table :local_avatars do |t|
      t.belongs_to :user, index: true
      t.binary :image_data, null: false, limit: 10.megabyte
      t.timestamps
    end
  end
end
