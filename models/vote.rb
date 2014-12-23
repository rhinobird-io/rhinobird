class Vote < ActiveRecord::Base
  validates :title, uniqueness: true
  has_and_belongs_to_many :user
  has_many :question
end