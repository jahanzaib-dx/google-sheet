class AddCustomToSaleRecord < ActiveRecord::Migration
  def change
    add_column :sale_records, :custom, :hstore
  end
end
