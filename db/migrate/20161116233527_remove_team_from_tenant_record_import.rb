class RemoveTeamFromTenantRecordImport < ActiveRecord::Migration
  def change
    remove_column :tenant_record_imports, :team_id
  end
end
