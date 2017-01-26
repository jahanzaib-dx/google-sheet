class AddParentIdToSaleRecords < ActiveRecord::Migration
  def change
    add_column :sale_records, :parent_id, :integer
  end
end
