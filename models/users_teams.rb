class UsersTeam < ActiveRecord::Base
  belongs_to :user
  belongs_to :team

  scope :with_team, ->(team) { where(group_id: team.id)}
  scope :with_user, ->(user) { where(user_id: user.id)}

  validates_presence_of :user_id
  validates_presence_of :team_id
  validates :user_id, uniqueness: { scope: [:team_id], message: "already exists in team" }
end