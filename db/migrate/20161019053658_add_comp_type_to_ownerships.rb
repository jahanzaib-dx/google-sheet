class AddCompTypeToOwnerships < ActiveRecord::Migration
  def change
    add_column :ownerships, :comp_type, :string
  end
end
