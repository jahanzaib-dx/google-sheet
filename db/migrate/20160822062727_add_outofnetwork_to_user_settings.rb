class AddOutofnetworkToUserSettings < ActiveRecord::Migration
  def change
    add_column :user_settings, :outofnetwork, :boolean
  end
end
