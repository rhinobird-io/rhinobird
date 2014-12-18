class Team < ActiveRecord::Base
  validates :team_name, presence: true, uniqueness: true
	has_many :users_teams, dependent: :destroy
  has_many :users, :through => :users_teams
end