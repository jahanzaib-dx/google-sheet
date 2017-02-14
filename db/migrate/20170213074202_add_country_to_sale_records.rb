class AddCountryToSaleRecords < ActiveRecord::Migration
  def change
    add_column :sale_records, :country, :string
  end
end
