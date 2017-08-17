class CreateWhiteGloveServiceRequests < ActiveRecord::Migration
  def change
    create_table :white_glove_service_requests do |t|
      t.references :user, index: true
      t.string :file_path
      t.references :import_template, index: true

      t.timestamps null: false
    end
    add_foreign_key :white_glove_service_requests, :users
    add_foreign_key :white_glove_service_requests, :import_templates
  end
end
