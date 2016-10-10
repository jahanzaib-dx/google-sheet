class AddPropertyTypeToSaleRecords < ActiveRecord::Migration
  def change
    add_column :sale_records, :property_type, :string
  end
end
