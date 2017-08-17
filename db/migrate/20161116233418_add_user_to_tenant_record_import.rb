class AddUserToTenantRecordImport < ActiveRecord::Migration
  def change
    add_reference :tenant_record_imports, :user, index: true
    add_foreign_key :tenant_record_imports, :users
  end
end
