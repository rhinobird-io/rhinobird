class VoteStatus < ActiveRecord::Base
  belongs_to :vote

  validates :user, uniqueness: { scope: [:vote_id], message: "already involved in this vote" }
end