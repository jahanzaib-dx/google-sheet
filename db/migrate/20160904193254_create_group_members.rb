class CreateGroupMembers < ActiveRecord::Migration
  def change
    create_table :group_members do |t|
      t.references :group, index: true
      t.references :member, index: true

      t.timestamps null: false
    end
    add_foreign_key :group_members, :groups
    add_foreign_key :group_members, :users, column: :member_id
  end
end
