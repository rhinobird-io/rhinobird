class TeamsRelation < ActiveRecord::Base
  validates :parent_team_id, presence: true
  validates :team_id, presence: true
end