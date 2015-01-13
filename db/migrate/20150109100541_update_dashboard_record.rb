class UpdateDashboardRecord < ActiveRecord::Migration
  def change
    add_column :dashboard_records, :from_user_id, :integer
  end
end
