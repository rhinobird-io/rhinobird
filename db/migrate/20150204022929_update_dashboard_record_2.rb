class UpdateDashboardRecord2 < ActiveRecord::Migration
  def change
    add_column :dashboard_records, :has_link, :boolean
    add_column :dashboard_records, :link_url, :string
    add_column :dashboard_records, :link_title, :string
  end
end
