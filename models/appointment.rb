class Appointment < ActiveRecord::Base
  belongs_to :event
  belongs_to :participant, class_name: :User
end