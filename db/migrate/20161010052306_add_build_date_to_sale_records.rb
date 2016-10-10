class AddBuildDateToSaleRecords < ActiveRecord::Migration
  def change
    add_column :sale_records, :build_date, :date
  end
end
