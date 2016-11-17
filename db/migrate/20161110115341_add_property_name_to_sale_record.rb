class AddPropertyNameToSaleRecord < ActiveRecord::Migration
  def change
    add_column :sale_records, :property_name, :string
  end
end
