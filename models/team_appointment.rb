class TeamAppointment < ActiveRecord::Base
  belongs_to :event
  belongs_to :team_participant, class_name: :Team
end