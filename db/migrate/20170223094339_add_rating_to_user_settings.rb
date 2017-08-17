class AddRatingToUserSettings < ActiveRecord::Migration
  def change
    add_column :user_settings, :rating, :integer
  end
end
