class LocalAvatar < ActiveRecord::Base
  validates :image_data, presence: true
  belongs_to :user
end