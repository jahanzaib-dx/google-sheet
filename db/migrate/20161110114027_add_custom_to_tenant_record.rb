class AddCustomToTenantRecord < ActiveRecord::Migration
  def change
    add_column :tenant_records, :custom, :hstore
  end
end
