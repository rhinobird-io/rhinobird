class CreateVotes < ActiveRecord::Migration
  def change
    create_table :votes do |t|
      t.text :title

      t.timestamps
    end

    create_table :questions do |t|
      t.belongs_to :vote
      t.text :description
      t.text :options
    end

    create_table :users_votes do |t|
      t.belongs_to :vote, index: true
      t.belongs_to :user, index: true
      t.boolean :finished

      t.timestamps
    end
  end
end
