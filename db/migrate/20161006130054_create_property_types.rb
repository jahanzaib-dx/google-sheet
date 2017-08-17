class CreatePropertyTypes < ActiveRecord::Migration
  def change
    unless ActiveRecord::Base.connection.table_exists? 'property_types'
      create_table :property_types do |t|
        t.string :name

        t.timestamps
      end
    end
  end
end
