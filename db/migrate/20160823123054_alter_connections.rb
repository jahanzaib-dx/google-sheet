class AlterConnections < ActiveRecord::Migration
  def change

    add_column :connections, :agent_id , :integer, :references => "users"

    remove_column :connections, :con_id
    remove_column :connections, :message
    remove_column :connections, :status
  end
end
