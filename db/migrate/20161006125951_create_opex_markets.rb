class CreateOpexMarkets < ActiveRecord::Migration
  def change
    unless ActiveRecord::Base.connection.table_exists? 'opex_markets'
      create_table :opex_markets do |t|

        t.string :name
        t.string :code
        t.string :description

        t.references :property_type
        t.timestamps
      end
    end
  end
end
