class AddIsGeoCodedToSaleRecords < ActiveRecord::Migration
  def change
    add_column :sale_records, :is_geo_coded, :boolean
  end
end
