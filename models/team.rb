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

  def get_all_users
    (self.users + self.teams.map {|t| t.get_all_users}.flatten).uniq
  end

  def get_all_sub_teams
    (self.teams + self.teams.map{|t| t.get_all_sub_teams}.flatten).uniq
  end

  def get_all_parent_teams
    (self.parent_teams + self.parent_teams.map{|t| t.get_all_parent_teams}.flatten).uniq
  end
end