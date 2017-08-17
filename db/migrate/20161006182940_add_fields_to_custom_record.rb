class AddFieldsToCustomRecord < ActiveRecord::Migration
  def change
    unless CustomRecord.column_names.include? 'team_id'
      add_column :custom_records, :zipcode, :string
    end
    unless CustomRecord.column_names.include? 'team_id'
      add_column :custom_records, :zipcode_plus, :string
    end
  end
end
