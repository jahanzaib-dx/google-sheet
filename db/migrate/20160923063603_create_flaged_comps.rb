class CreateFlagedComps < ActiveRecord::Migration
  def change
    create_table :flaged_comps do |t|
      t.integer :comp_id
      t.integer :user_id

      t.timestamps null: false
    end
  end
end
