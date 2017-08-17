class CreateMarketExpenses < ActiveRecord::Migration
  def change
    unless ActiveRecord::Base.connection.table_exists? 'market_expenses'
      create_table :market_expenses do |t|

        t.decimal :taxes, precision: 20, scale: 2
        t.decimal :insurance, precision: 20, scale: 2
        t.decimal :utilities, precision: 20, scale: 2
        t.decimal :cam, precision: 20, scale: 2
        t.decimal :janitorial, precision: 20, scale: 2
        t.decimal :administrative, precision: 20, scale: 2
        t.decimal :payroll_and_benefits, precision: 20, scale: 2
        t.decimal :management_fee, precision: 20, scale: 2
        t.decimal :grounds_landscape, precision: 20, scale: 2
        t.decimal :security, precision: 20, scale: 2
        t.decimal :other_tax, precision: 20, scale: 2
        t.decimal :total_opex, precision: 20, scale: 2

        t.references :opex_market

        t.timestamps
      end
    end
  end
end
