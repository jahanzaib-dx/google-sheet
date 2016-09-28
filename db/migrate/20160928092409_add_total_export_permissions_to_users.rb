class AddTotalExportPermissionsToUsers < ActiveRecord::Migration
  def change
    add_column :users, :total_export_permissions, :integer
  end
end
