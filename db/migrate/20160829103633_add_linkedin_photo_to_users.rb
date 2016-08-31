class AddLinkedinPhotoToUsers < ActiveRecord::Migration
 def change
      add_column :users, :linkedin_photo, :string
  end
end