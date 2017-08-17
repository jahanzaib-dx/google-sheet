class AddIsGeoCodedToTenantRecords < ActiveRecord::Migration
  def change
    add_column :tenant_records, :is_geo_coded, :boolean
  end
end
