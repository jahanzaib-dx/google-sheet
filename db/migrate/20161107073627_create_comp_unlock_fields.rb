class CreateCompUnlockFields < ActiveRecord::Migration
  def change
    create_table :comp_unlock_fields do |t|
      t.integer :shared_comp_id
      t.string :field_name
    end
  end
end
