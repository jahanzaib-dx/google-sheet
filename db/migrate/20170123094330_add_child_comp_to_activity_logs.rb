class AddChildCompToActivityLogs < ActiveRecord::Migration
  def change
    add_column :activity_logs, :child_comp, :integer
  end
end
