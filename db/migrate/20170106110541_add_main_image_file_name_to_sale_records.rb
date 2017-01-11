class AddMainImageFileNameToSaleRecords < ActiveRecord::Migration
  def change
    add_column :sale_records, :main_image_file_name, :string
  end
end
