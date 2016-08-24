class ChangeColumns < ActiveRecord::Migration
  def change
    add_foreign_key :requests, :users, column: :initiator_id
    add_foreign_key :requests, :users, column: :receiver_id
    add_foreign_key :requests, :tenant_records, column: :comp_id

  end
end
