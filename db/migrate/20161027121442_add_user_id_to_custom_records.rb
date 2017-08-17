class AddUserIdToCustomRecords < ActiveRecord::Migration
  def change
    add_reference :custom_records, :user, index: true
    add_foreign_key :custom_records, :users
  end
end
