class Event < ActiveRecord::Base



  belongs_to :creator, class_name: :User
  has_many :appointments
  has_many :participants, through: :appointments
end