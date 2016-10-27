class CreateCustomRecords < ActiveRecord::Migration
  def change
    unless ActiveRecord::Base.connection.table_exists? 'custom_records'
      create_table :custom_records do |t|

        t.boolean :is_existing_data_set, default: false
        t.boolean :is_geo_coded, default: false
        t.string  :name
        t.string  :address1
        t.string  :city
        t.string  :state
        t.decimal :latitude, :precision => 30, :scale => 9
        t.decimal :longitude, :precision => 30, :scale => 9

        t.timestamps
      end
    end
  end
end
