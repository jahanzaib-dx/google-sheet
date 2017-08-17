class CreateGroups < ActiveRecord::Migration
  def change
    drop_table :groups

    create_table :groups do |t|
      t.references :user, index: true
      t.string :title, limit: 255

      t.timestamps null: false
    end
    add_foreign_key :groups, :users
  end
end
