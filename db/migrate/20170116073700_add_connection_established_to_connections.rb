class AddConnectionEstablishedToConnections < ActiveRecord::Migration
  def change
    add_column :connections, :connection_established, :boolean
  end
end
