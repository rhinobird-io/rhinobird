class DashboardRecord < ActiveRecord::Base
  validates :content, presence: true
end