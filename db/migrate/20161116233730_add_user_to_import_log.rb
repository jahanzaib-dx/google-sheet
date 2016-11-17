class AddUserToImportLog < ActiveRecord::Migration
  def change
    add_reference :import_logs, :user, index: true
    add_foreign_key :import_logs, :users
  end
end
