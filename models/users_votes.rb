class UsersVotes < ActiveRecord::Base
  belongs_to :user
  belongs_to :vote

  scope :with_vote, ->(vote) { where(vote_id: vote.id)}
  scope :with_user, ->(user) { where(user_id: user.id)}

  validates_presence_of :user_id
  validates_presence_of :vote_id
  validates :user_id, uniqueness: { scope: [:vote_id], message: "already involved in this vote" }
end