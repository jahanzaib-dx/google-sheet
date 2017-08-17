class AddFieldsToSaleRecord < ActiveRecord::Migration
  def change
    unless SaleRecord.column_names.include? 'zipcode'
      add_column :sale_records, :zipcode, :string
    end
    unless SaleRecord.column_names.include? 'zipcode_plus'
      add_column :sale_records, :zipcode_plus, :string
    end
  end
end
