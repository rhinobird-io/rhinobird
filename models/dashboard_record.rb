class DashboardRecord < ActiveRecord::Base
  validates :content, presence: true
  validates :from_user_id, presence: true
end