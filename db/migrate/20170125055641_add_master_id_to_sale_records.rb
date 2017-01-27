class AddMasterIdToSaleRecords < ActiveRecord::Migration
  def change
    add_column :sale_records, :master_id, :integer
  end
end
