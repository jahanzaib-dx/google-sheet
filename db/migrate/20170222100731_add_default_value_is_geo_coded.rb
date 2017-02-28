class AddDefaultValueIsGeoCoded < ActiveRecord::Migration
  def up
    change_column :tenant_records, :is_geo_coded, :boolean, :default => true
    change_column :sale_records, :is_geo_coded, :boolean, :default => true
    change_column :custom_records, :is_geo_coded, :boolean, :default => true
  end

  def down
    change_column :tenant_records, :is_geo_coded, :boolean, :default => nil
    change_column :sale_records, :is_geo_coded, :boolean, :default => nil
    change_column :custom_records, :is_geo_coded, :boolean, :default => nil
  end
end
