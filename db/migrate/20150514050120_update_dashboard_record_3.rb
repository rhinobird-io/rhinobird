class UpdateDashboardRecord3 < ActiveRecord::Migration
  def change
    add_column :dashboard_records, :link_to, :string
    add_column :dashboard_records, :link_param, :string
  end
end
