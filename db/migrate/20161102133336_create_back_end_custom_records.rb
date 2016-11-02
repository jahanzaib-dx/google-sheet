class CreateBackEndCustomRecords < ActiveRecord::Migration
  def change
    create_table :back_end_custom_records do |t|
      t.integer :custom_record_id
      t.string :file

      t.timestamps null: false
    end
  end
end
