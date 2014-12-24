class Vote < ActiveRecord::Base
  validates :title, uniqueness: true
  has_many :question
  has_many :vote_status
end