class RemoveOfficeFromTenantRecordImport < ActiveRecord::Migration
  def change
    remove_column :tenant_record_imports, :office_id
  end
end
