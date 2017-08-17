class CreateIndustries < ActiveRecord::Migration
  def change
    unless ActiveRecord::Base.connection.table_exists? 'industries'
      create_table :industries do |t|
        t.string :name

        t.timestamps
      end
    end
  end
end
