class AddTypeToImportTemplate < ActiveRecord::Migration
  def change
    add_column :import_templates, :type, :string, :limit=>30
  end
end
