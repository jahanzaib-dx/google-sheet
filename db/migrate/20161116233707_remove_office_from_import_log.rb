class RemoveOfficeFromImportLog < ActiveRecord::Migration
  def change
    remove_column :import_logs, :office_id
  end
end
