class Team < ActiveRecord::Base
  validates :name, presence: true, uniqueness: true
	has_many :users_teams, dependent: :destroy
  has_many :users, :through => :users_teams

  has_many :team_appointments, foreign_key: :team_participant_id
  has_many :events, through: :team_appointments
  has_many :team_snapshots

  has_many :teams_relations, foreign_key: 'parent_team_id'
  has_many :teams, through: :teams_relations

  has_many :parent_teams_relations, foreign_key: 'team_id', class_name: 'TeamsRelation'
  has_many :parent_teams, through: :parent_teams_relations, source: :parent_team
end