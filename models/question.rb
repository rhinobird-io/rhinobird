class Question < ActiveRecord::Base
  validates :description, presence: true
  validates :options, presence: true
  belongs_to :vote
end