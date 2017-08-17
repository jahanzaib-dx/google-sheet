class AddCompIdToOwnerships < ActiveRecord::Migration
  def change
    add_column :ownerships, :comp_id, :integer
  end
end
