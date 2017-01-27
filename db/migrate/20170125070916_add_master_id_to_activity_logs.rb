class AddMasterIdToActivityLogs < ActiveRecord::Migration
  def change
    add_column :activity_logs, :master_id, :integer
  end
end
