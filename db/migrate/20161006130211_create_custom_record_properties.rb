class CreateCustomRecordProperties < ActiveRecord::Migration
  def change
    unless ActiveRecord::Base.connection.table_exists? 'custom_record_properties'
      create_table :custom_record_properties do |t|

        t.string :key
        t.string :value
        t.references :custom_record

        t.timestamps
      end
    end
  end
end
