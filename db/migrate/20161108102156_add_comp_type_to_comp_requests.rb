class AddCompTypeToCompRequests < ActiveRecord::Migration
  def change
    add_column :comp_requests, :comp_type, :string
  end
end
