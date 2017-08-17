class AddRowNoToCustomRecordProperty < ActiveRecord::Migration
  def change
    add_column :custom_record_properties, :row_id, :integer
  end
end
