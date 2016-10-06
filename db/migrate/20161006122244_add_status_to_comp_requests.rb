class AddStatusToCompRequests < ActiveRecord::Migration
  def change
    add_column :comp_requests, :status, :boolean, default: false
  end
end
