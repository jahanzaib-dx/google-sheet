class AddUserIdToSaleRecord < ActiveRecord::Migration
  def change
    add_reference :sale_records, :user, index: true
    add_foreign_key :sale_records, :users
  end
end
