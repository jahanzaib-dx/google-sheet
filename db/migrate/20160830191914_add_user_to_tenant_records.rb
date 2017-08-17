class AddUserToTenantRecords < ActiveRecord::Migration
  def change
    add_reference :tenant_records, :user, index: true
    #add_foreign_key :tenant_records, :users
  end
end
