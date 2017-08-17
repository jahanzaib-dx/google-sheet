class AlterActivityLog < ActiveRecord::Migration
  def change
    rename_column :activity_logs, :sender_id, :initiator_id
  end
end
