class CreateTenantRecordImportOperatingExpenseMappings < ActiveRecord::Migration
  def change
    create_table :tenant_record_import_operating_expense_mappings do |t|
      t.references :tenant_record_import
      t.string :column_name

      t.timestamps null: false
    end
    add_index :tenant_record_import_operating_expense_mappings, :tenant_record_import_id, name: 'index_tr_import_oe_mappings_on_tr_import_id'
    add_foreign_key :tenant_record_import_operating_expense_mappings, :tenant_record_imports
  end
end
