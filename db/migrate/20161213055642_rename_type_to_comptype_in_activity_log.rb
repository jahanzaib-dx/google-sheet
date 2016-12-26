class RenameTypeToComptypeInActivityLog < ActiveRecord::Migration
  def change
    rename_column :activity_logs, :type, :comptype
  end
end
