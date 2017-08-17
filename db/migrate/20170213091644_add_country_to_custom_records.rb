class AddCountryToCustomRecords < ActiveRecord::Migration
  def change
    add_column :custom_records, :country, :string
  end
end
