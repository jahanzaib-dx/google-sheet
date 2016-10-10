class AddSoldDateToSaleRecords < ActiveRecord::Migration
  def change
    add_column :sale_records, :sold_date, :date
  end
end
