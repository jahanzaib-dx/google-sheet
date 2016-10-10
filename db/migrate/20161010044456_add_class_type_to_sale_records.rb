class AddClassTypeToSaleRecords < ActiveRecord::Migration
  def change
    add_column :sale_records, :class_type, :string
  end
end
