class AddVisibleToCustomRecordProperty < ActiveRecord::Migration
  def change
    add_column :custom_record_properties, :visible, :boolean, :default => true
  end
end
