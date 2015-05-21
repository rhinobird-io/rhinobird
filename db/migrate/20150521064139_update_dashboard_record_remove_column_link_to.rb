class UpdateDashboardRecordRemoveColumnLinkTo < ActiveRecord::Migration
  def change
    remove_column :dashboard_records, :link_to
  end
end
