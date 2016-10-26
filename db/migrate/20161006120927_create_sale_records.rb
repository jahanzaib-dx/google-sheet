class CreateSaleRecords < ActiveRecord::Migration
  def change
    unless ActiveRecord::Base.connection.table_exists? 'sale_records'
      create_table :sale_records do |t|

        t.boolean :is_sales_record, default: false
        t.string  :land_size_identifier
        t.string  :view_type
        t.string  :address1
        t.string  :city
        t.string  :state
        t.decimal :land_size, :precision => 20, :scale => 2
        t.decimal :price, :precision => 20, :scale => 2
        t.decimal :cap_rate, :precision => 20, :scale => 2
        t.decimal :latitude, :precision => 30, :scale => 9
        t.decimal :longitude, :precision => 30, :scale => 9

        t.timestamps
      end
    end
  end
end
