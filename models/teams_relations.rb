class TeamsRelation < ActiveRecord::Base
  validates :parent_team_id, presence: true
  validates :team_id, presence: true
  validate :has_circle

  def has_circle

    reverse_origin = team_id
    reverse_parent_array = [parent_team_id]

    until reverse_parent_array == []

      if reverse_parent_array.include?(reverse_origin)
        errors.add(:parent_team_id, parent_team_id.to_s + " has formed a circle of relation with given team id " + team_id.to_s)
        return
      end

      temp_array = []
      reverse_parent_array.each do |parent_id|
        parent_array = TeamsRelation.where(team_id: parent_id).pluck(:parent_team_id)
        temp_array = temp_array | parent_array
      end
      reverse_parent_array = temp_array
    end
  end
end