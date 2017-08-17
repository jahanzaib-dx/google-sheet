class AddUsernameToUsers < ActiveRecord::Migration
  def change
    add_column :users, :username, :string
	add_column :users, :mobile, :string
	add_column :users, :email_code, :string
	add_column :users, :sms_code, :string
	add_column :users, :linkedin, :string
	
  end
end
