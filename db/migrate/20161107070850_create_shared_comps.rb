class CreateSharedComps < ActiveRecord::Migration
  def change
    create_table :shared_comps do |t|
      t.integer :comp_id
      t.integer :agent_id
      t.string :comp_type
      t.string :comp_status
      t.boolean :ownership, default: false
    end
  end
end
