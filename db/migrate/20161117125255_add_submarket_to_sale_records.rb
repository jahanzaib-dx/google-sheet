class AddSubmarketToSaleRecords < ActiveRecord::Migration
  def change
    add_column :sale_records, :submarket, :string
  end
end
