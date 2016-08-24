class AddTypeToActivityLogs < ActiveRecord::Migration
  def change
    add_column :activity_logs, :type, :string
  end
end
