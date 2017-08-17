class ChangeColumnToTenantRecord < ActiveRecord::Migration
  def self.up
    rename_column :tenant_records, :custom, :custom_data
  end

  def self.down

  end
end
