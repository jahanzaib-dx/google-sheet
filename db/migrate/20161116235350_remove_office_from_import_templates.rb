class RemoveOfficeFromImportTemplates < ActiveRecord::Migration
  def change
    remove_column :import_templates, :office_id
  end
end
