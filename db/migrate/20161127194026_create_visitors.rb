class CreateVisitors < ActiveRecord::Migration
  def change
    create_table :visitors do |t|
      t.string :page, limit: 100
      t.string :email
      t.string :ip, limit: 15

      t.timestamps null: false
    end
  end
end
