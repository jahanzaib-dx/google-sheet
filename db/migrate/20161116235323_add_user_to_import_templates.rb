class AddUserToImportTemplates < ActiveRecord::Migration
  def change
    add_reference :import_templates, :user, index: true
    add_foreign_key :import_templates, :users
  end
end
