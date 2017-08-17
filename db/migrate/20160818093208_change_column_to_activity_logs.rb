class ChangeColumnToActivityLogs < ActiveRecord::Migration
  def up
  	rename_column :activity_logs, :created_by, :sender_id
	rename_column :activity_logs, :updated_by, :receiver_id
  end

  def down
  end
end
