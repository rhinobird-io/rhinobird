class Team < ActiveRecord::Base
  validates :name, presence: true, uniqueness: true
	has_many :users_teams, dependent: :destroy
  has_many :users, :through => :users_teams

  has_many :team_appointments, foreign_key: :team_participant_id
  has_many :events, through: :team_appointments
  has_many :team_snapshots
end