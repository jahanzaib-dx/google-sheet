class CreateBackEndSaleComps < ActiveRecord::Migration
  def change
    create_table :back_end_sale_comps do |t|
      t.integer :user_id
      t.string :file

      t.timestamps null: false
    end
  end
end
