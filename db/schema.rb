# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20160823123711) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "hstore"
  enable_extension "postgis"

  create_table "account_features", force: :cascade do |t|
    t.boolean  "show_tenantrex_cashflow",             default: false
    t.boolean  "show_tenantrex_output",               default: false
    t.integer  "account_id"
    t.datetime "created_at",                                              null: false
    t.datetime "updated_at",                                              null: false
    t.string   "account_type",            limit: 255, default: "cushman"
  end

  create_table "accounts", force: :cascade do |t|
    t.string   "fullname",                  limit: 255
    t.string   "role",                      limit: 255
    t.integer  "user_id"
    t.integer  "firm_id"
    t.integer  "office_id"
    t.datetime "created_at",                                            null: false
    t.datetime "updated_at",                                            null: false
    t.integer  "market_id"
    t.boolean  "accepted_terms_of_service",             default: false
  end

  add_index "accounts", ["firm_id"], name: "index_accounts_on_firm_id", using: :btree
  add_index "accounts", ["office_id"], name: "index_accounts_on_office_id", using: :btree
  add_index "accounts", ["user_id"], name: "index_accounts_on_user_id", using: :btree

  create_table "accounts_teams", force: :cascade do |t|
    t.integer "account_id"
    t.integer "team_id"
  end

  create_table "activity_logs", force: :cascade do |t|
    t.integer  "comp_id"
    t.string   "status",      limit: 255
    t.integer  "sender_id"
    t.integer  "receiver_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "type",        limit: 255
  end

  create_table "agreements", force: :cascade do |t|
    t.string   "name",                 limit: 255
    t.text     "description"
    t.boolean  "office_default",                   default: false
    t.datetime "agreement_start_date"
    t.datetime "agreement_end_date"
    t.datetime "deleted_at"
    t.datetime "created_at",                                       null: false
    t.datetime "updated_at",                                       null: false
  end

  create_table "agreements_offices", id: false, force: :cascade do |t|
    t.integer "agreement_id"
    t.integer "office_id"
  end

  add_index "agreements_offices", ["agreement_id", "office_id"], name: "index_agreements_offices_on_agreement_id_and_office_id", unique: true, using: :btree
  add_index "agreements_offices", ["office_id"], name: "index_agreements_offices_on_office_id", using: :btree

  create_table "agreements_tenant_records", id: false, force: :cascade do |t|
    t.integer "agreement_id"
    t.integer "tenant_record_id"
  end

  add_index "agreements_tenant_records", ["agreement_id", "tenant_record_id"], name: "index_agreement_tenant_record", unique: true, using: :btree
  add_index "agreements_tenant_records", ["tenant_record_id"], name: "index_agreements_tenant_records_on_tenant_record_id", using: :btree

  create_table "archive_migration_tenant_records", force: :cascade do |t|
    t.string  "image_url",                   limit: 255
    t.integer "confidential"
    t.string  "website",                     limit: 255
    t.decimal "tenant_improvement_modifier",             precision: 20
    t.decimal "insurance",                               precision: 20
    t.decimal "maintenance",                             precision: 20
    t.decimal "utilities",                               precision: 20
    t.decimal "taxes",                                   precision: 20
    t.date    "lease_commencement"
    t.date    "lease_expiration"
  end

  create_table "attached_files", force: :cascade do |t|
    t.integer "message_id",             null: false
    t.string  "file_name",  limit: 255
  end

  create_table "comp_requests", force: :cascade do |t|
    t.integer  "comp_id"
    t.integer  "initiator_id"
    t.integer  "receiver_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "comp_requests", ["comp_id"], name: "index_comp_requests_on_comp_id", using: :btree
  add_index "comp_requests", ["initiator_id"], name: "index_comp_requests_on_initiator_id", using: :btree
  add_index "comp_requests", ["receiver_id"], name: "index_comp_requests_on_receiver_id", using: :btree

  create_table "connection_requests", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "agent_id"
    t.string   "message"
    t.string   "request_code"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "connection_requests", ["agent_id"], name: "index_connection_requests_on_agent_id", using: :btree
  add_index "connection_requests", ["user_id"], name: "index_connection_requests_on_user_id", using: :btree

  create_table "connections", force: :cascade do |t|
    t.integer  "user_id",    limit: 8
    t.datetime "created_at"
    t.integer  "group_id"
    t.integer  "agent_id"
  end

  create_table "custom_report_header_custom_fields", force: :cascade do |t|
    t.integer  "custom_report_header_id"
    t.string   "custom_field_name",       limit: 255
    t.integer  "order"
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
  end

  create_table "custom_report_header_fields", force: :cascade do |t|
    t.integer  "custom_report_header_id"
    t.integer  "tenant_record_sub_category_id"
    t.integer  "order"
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
  end

  create_table "custom_report_headers", force: :cascade do |t|
    t.string   "bg_color",                  limit: 255
    t.integer  "tenant_record_category_id"
    t.integer  "custom_report_id"
    t.integer  "order"
    t.datetime "created_at",                            null: false
    t.datetime "updated_at",                            null: false
    t.string   "header_name",               limit: 255
  end

  create_table "custom_report_summary_column_names", force: :cascade do |t|
    t.string   "label_name",                     limit: 255
    t.integer  "custom_report_id"
    t.integer  "custom_report_summary_field_id"
    t.datetime "created_at",                                 null: false
    t.datetime "updated_at",                                 null: false
    t.integer  "order"
  end

  create_table "custom_report_summary_fields", force: :cascade do |t|
    t.string   "field_name", limit: 255
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
    t.string   "label_name", limit: 255
  end

  create_table "custom_reports", force: :cascade do |t|
    t.string   "name",               limit: 255
    t.string   "bg_color",           limit: 255
    t.string   "template_type",      limit: 255
    t.integer  "report_template_id"
    t.integer  "user_id"
    t.datetime "created_at",                                     null: false
    t.datetime "updated_at",                                     null: false
    t.boolean  "default",                        default: false
  end

  create_table "expenses", force: :cascade do |t|
    t.string  "name",          limit: 255
    t.integer "display_order",             default: 0
  end

  create_table "firms", force: :cascade do |t|
    t.string   "name",          limit: 255
    t.string   "contact_name",  limit: 255
    t.string   "contact_email", limit: 255
    t.string   "contact_phone", limit: 255
    t.datetime "deleted_at"
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
  end

  create_table "groups", force: :cascade do |t|
    t.integer "name", null: false
  end

  create_table "import_logs", force: :cascade do |t|
    t.integer  "tenant_record_import_id"
    t.integer  "office_id"
    t.integer  "tenant_record_id"
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
  end

  create_table "import_mappings", force: :cascade do |t|
    t.integer  "import_template_id"
    t.string   "spreadsheet_column", limit: 255
    t.string   "record_column",      limit: 255
    t.datetime "created_at",                     null: false
    t.datetime "updated_at",                     null: false
    t.string   "default_value",      limit: 255
  end

  create_table "import_records", force: :cascade do |t|
    t.integer "tenant_record_import_id"
    t.boolean "record_valid",            default: false
    t.boolean "geocode_valid",           default: false
    t.boolean "imported",                default: false
    t.text    "record_warnings"
    t.hstore  "data"
    t.hstore  "record_errors"
  end

  create_table "import_templates", force: :cascade do |t|
    t.integer  "office_id"
    t.string   "name",       limit: 255
    t.datetime "created_at",                            null: false
    t.datetime "updated_at",                            null: false
    t.boolean  "reusable",               default: true
  end

  add_index "import_templates", ["name", "office_id", "reusable"], name: "index_import_templates_on_name_and_office_id_and_reusable", unique: true, using: :btree

  create_table "industry_sic_codes", force: :cascade do |t|
    t.string "value",               limit: 255
    t.string "description",         limit: 255
    t.string "division",            limit: 255
    t.string "major_group",         limit: 255
    t.string "industry_group",      limit: 255
    t.string "division_desc",       limit: 255
    t.string "major_group_desc",    limit: 255
    t.string "industry_group_desc", limit: 255
  end

  create_table "learn_more_requests", force: :cascade do |t|
    t.string   "fullname",       limit: 255
    t.string   "brokerage_firm", limit: 255
    t.string   "email",          limit: 255
    t.integer  "market_id"
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
  end

  create_table "lease_structure_expenses", force: :cascade do |t|
    t.integer "lease_structure_id"
    t.string  "calculation_type",   limit: 255
    t.decimal "default_cost"
    t.decimal "increase_percent"
    t.date    "start_date"
    t.string  "name",               limit: 255
  end

  add_index "lease_structure_expenses", ["lease_structure_id"], name: "index_lease_structure_expenses_on_lease_structure_id", using: :btree

  create_table "lease_structures", force: :cascade do |t|
    t.string  "name",          limit: 255
    t.text    "description"
    t.integer "account_id"
    t.decimal "discount_rate",             precision: 4, scale: 2
    t.integer "office_id"
    t.decimal "interest_rate",             precision: 4, scale: 2, default: 0.0
  end

  add_index "lease_structures", ["name", "account_id"], name: "index_lease_structures_on_name_and_account_id", unique: true, using: :btree

# Could not dump table "lookup_address_zipcodes" because of following StandardError
#   Unknown type 'geometry(Point,3785)' for column 'location'

  create_table "lookup_address_zipcodes_tenant_records", id: false, force: :cascade do |t|
    t.integer "tenant_record_id"
    t.integer "lookup_address_zipcode_id"
  end

  create_table "lookup_companies", force: :cascade do |t|
    t.string "name", limit: 255
  end

  add_index "lookup_companies", ["name"], name: "index_lookup_companies_on_name", using: :btree

  create_table "lookup_companies_tenant_records", id: false, force: :cascade do |t|
    t.integer "tenant_record_id"
    t.integer "lookup_company_id"
  end

  create_table "lookup_property_names", force: :cascade do |t|
    t.string "name", limit: 255
  end

  add_index "lookup_property_names", ["name"], name: "index_lookup_property_names_on_name", using: :btree

  create_table "lookup_property_names_tenant_records", id: false, force: :cascade do |t|
    t.integer "tenant_record_id"
    t.integer "lookup_property_name_id"
  end

  create_table "lookup_submarkets", force: :cascade do |t|
    t.string "name", limit: 255
  end

  add_index "lookup_submarkets", ["name"], name: "index_lookup_submarkets_on_name", using: :btree

  create_table "lookup_submarkets_tenant_records", id: false, force: :cascade do |t|
    t.integer "tenant_record_id"
    t.integer "lookup_submarket_id"
  end

  create_table "maps", force: :cascade do |t|
    t.integer  "account_id"
    t.integer  "office_id"
    t.string   "name",       limit: 255
    t.string   "mode",       limit: 255
    t.text     "latitude"
    t.text     "longitude"
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  add_index "maps", ["account_id"], name: "index_maps_on_account_id", using: :btree
  add_index "maps", ["office_id"], name: "index_maps_on_office_id", using: :btree

  create_table "markets", force: :cascade do |t|
    t.string  "name",         limit: 255
    t.boolean "is_preferred",             default: false
    t.string  "description",  limit: 255
  end

  create_table "messages", force: :cascade do |t|
    t.integer  "sender_id",                               null: false
    t.integer  "receiver_id",                             null: false
    t.text     "message"
    t.string   "file",        limit: 255
    t.boolean  "status",                  default: false
    t.datetime "created_at"
  end

  create_table "offices", force: :cascade do |t|
    t.integer  "firm_id"
    t.string   "name",                    limit: 255
    t.string   "contact_name",            limit: 255
    t.string   "contact_email",           limit: 255
    t.string   "contact_phone",           limit: 255
    t.decimal  "latitude",                            precision: 30, scale: 9
    t.decimal  "longitude",                           precision: 30, scale: 9
    t.string   "address1",                limit: 255
    t.string   "address2",                limit: 255
    t.string   "city",                    limit: 255
    t.string   "state",                   limit: 255
    t.integer  "zipcode"
    t.integer  "zipcode_plus"
    t.string   "logo_image_file_name",    limit: 255
    t.string   "logo_image_content_type", limit: 255
    t.integer  "logo_image_file_size"
    t.datetime "logo_image_updated_at"
    t.datetime "deleted_at"
    t.datetime "created_at",                                                   null: false
    t.datetime "updated_at",                                                   null: false
    t.string   "registration_code",       limit: 255
  end

  add_index "offices", ["firm_id"], name: "index_offices_on_firm_id", using: :btree

  create_table "ownerships", force: :cascade do |t|
    t.integer "account_id"
    t.integer "tenant_record_id"
  end

  create_table "report_templates", force: :cascade do |t|
    t.string   "template_name", limit: 255
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
  end

  create_table "requests", force: :cascade do |t|
    t.integer  "comp_id"
    t.integer  "initiator_id"
    t.integer  "receiver_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "requests", ["comp_id"], name: "index_requests_on_comp_id_id", using: :btree
  add_index "requests", ["initiator_id"], name: "index_requests_on_initiator_id_id", using: :btree
  add_index "requests", ["receiver_id"], name: "index_requests_on_receiver_id_id", using: :btree

  create_table "spatial_ref_sys", primary_key: "srid", force: :cascade do |t|
    t.string  "auth_name", limit: 256
    t.integer "auth_srid"
    t.string  "srtext",    limit: 2048
    t.string  "proj4text", limit: 2048
  end

  create_table "stepped_rents", force: :cascade do |t|
    t.integer  "tenant_record_id"
    t.integer  "order"
    t.integer  "months"
    t.decimal  "cost_per_month",   precision: 20, scale: 2
    t.datetime "deleted_at"
  end

  add_index "stepped_rents", ["deleted_at"], name: "index_stepped_rents_on_deleted_at", using: :btree

  create_table "teams", force: :cascade do |t|
    t.integer  "office_id"
    t.string   "name",       limit: 255
    t.text     "comment"
    t.datetime "created_at",                            null: false
    t.datetime "updated_at",                            null: false
    t.boolean  "multi_user",             default: true
  end

  create_table "tenant_record_categories", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  create_table "tenant_record_category_fields", force: :cascade do |t|
    t.string   "label_name",                limit: 255
    t.string   "tenant_record_field",       limit: 255
    t.integer  "tenant_record_category_id"
    t.integer  "order"
    t.datetime "created_at",                            null: false
    t.datetime "updated_at",                            null: false
  end

  create_table "tenant_record_images", force: :cascade do |t|
    t.integer  "tenant_record_id"
    t.string   "image_file_name",    limit: 255
    t.string   "image_content_type", limit: 255
    t.integer  "image_file_size"
    t.datetime "image_updated_at"
    t.datetime "created_at",                     null: false
    t.datetime "updated_at",                     null: false
  end

  create_table "tenant_record_imports", force: :cascade do |t|
    t.integer  "office_id"
    t.integer  "import_template_id"
    t.boolean  "complete",              default: false
    t.boolean  "import_valid",          default: false
    t.datetime "completed_at"
    t.datetime "created_at",                            null: false
    t.datetime "updated_at",                            null: false
    t.boolean  "geocode_valid"
    t.text     "status"
    t.integer  "total_record_count",    default: 0
    t.integer  "num_imported_records",  default: 0
    t.integer  "lease_structure_id"
    t.integer  "team_id"
    t.integer  "total_traversed_count", default: 0
  end

  create_table "tenant_records", force: :cascade do |t|
    t.integer  "office_id"
    t.text     "comments"
    t.integer  "industry_sic_code_id"
    t.string   "company",                       limit: 255
    t.string   "address1",                      limit: 255
    t.string   "suite",                         limit: 255
    t.string   "city",                          limit: 255
    t.string   "state",                         limit: 255
    t.string   "zipcode",                       limit: 255
    t.integer  "zipcode_plus"
    t.string   "view_type",                     limit: 255,                          default: "public"
    t.string   "comp_type",                     limit: 255,                          default: "internal"
    t.string   "contact",                       limit: 255
    t.string   "contact_email",                 limit: 255
    t.string   "contact_phone",                 limit: 255
    t.string   "location_type",                 limit: 255
    t.date     "lease_commencement_date"
    t.integer  "lease_term_months"
    t.string   "lease_type",                    limit: 255
    t.string   "property_type",                 limit: 255
    t.string   "class_type",                    limit: 255
    t.integer  "version",                                                            default: 1
    t.string   "mongoid",                       limit: 255
    t.decimal  "latitude",                                  precision: 30, scale: 9
    t.decimal  "longitude",                                 precision: 30, scale: 9
    t.integer  "size"
    t.decimal  "net_effective_per_sf",                      precision: 20, scale: 9, default: 0.0
    t.decimal  "landlord_concessions_per_sf",               precision: 20, scale: 9, default: 0.0
    t.decimal  "landlord_margins",                          precision: 20, scale: 9, default: 0.0
    t.decimal  "base_rent",                                 precision: 20, scale: 9
    t.decimal  "escalation",                                precision: 4,  scale: 2
    t.decimal  "tenant_improvement",                        precision: 20, scale: 9, default: 0.0
    t.decimal  "tenant_ti_cost",                            precision: 20, scale: 9, default: 0.0
    t.datetime "created_at",                                                                              null: false
    t.datetime "updated_at",                                                                              null: false
    t.datetime "deleted_at"
    t.hstore   "data"
    t.integer  "team_id"
    t.string   "main_image_file_name",          limit: 255
    t.string   "main_image_content_type",       limit: 255
    t.integer  "main_image_file_size"
    t.datetime "main_image_updated_at"
    t.decimal  "avg_base_rent_per_annum_by_sf"
    t.decimal  "landlord_effective_rent",                   precision: 20, scale: 9, default: 0.0
    t.string   "submarket",                     limit: 255
    t.string   "property_name",                 limit: 255
    t.integer  "free_rent_total",                                                    default: 0
    t.string   "free_rent",                     limit: 255,                          default: "0"
    t.string   "industry_type",                 limit: 255
    t.decimal  "cushman_net_effective_per_sf",              precision: 20, scale: 2, default: 0.0
    t.boolean  "is_stepped_rent",                                                    default: false
    t.string   "company_logo_file_name",        limit: 255
    t.string   "company_logo_content_type",     limit: 255
    t.integer  "company_logo_file_size"
    t.datetime "company_logo_updated_at"
  end

  add_index "tenant_records", ["industry_sic_code_id"], name: "index_tenant_records_on_industry_sic_code_id", using: :btree
  add_index "tenant_records", ["office_id"], name: "index_tenant_records_on_office_id", using: :btree

  create_table "user_settings", force: :cascade do |t|
    t.integer "user_id",      null: false
    t.boolean "sms"
    t.boolean "email"
    t.boolean "outofnetwork"
  end

  create_table "users", force: :cascade do |t|
    t.string   "email",                  limit: 255, default: "", null: false
    t.string   "encrypted_password",     limit: 255, default: "", null: false
    t.string   "reset_password_token",   limit: 255
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                      default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip",     limit: 255
    t.string   "last_sign_in_ip",        limit: 255
    t.datetime "created_at",                                      null: false
    t.datetime "updated_at",                                      null: false
    t.string   "username",               limit: 255
    t.string   "mobile",                 limit: 255
    t.string   "email_code",             limit: 255
    t.string   "sms_code",               limit: 255
    t.string   "linkedin",               limit: 255
    t.string   "confirmation_token",     limit: 255
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string   "unconfirmed_email",      limit: 255
    t.string   "provider",               limit: 255
    t.string   "uid",                    limit: 255
    t.boolean  "mobile_active"
    t.string   "first_name",             limit: 100
    t.string   "last_name",              limit: 100
    t.string   "title",                  limit: 30
    t.string   "firm_name",              limit: 100
    t.string   "address",                limit: 255
    t.string   "city",                   limit: 50
    t.string   "state",                  limit: 50
    t.string   "website",                limit: 150
    t.string   "zip",                    limit: 6
    t.string   "avatar",                 limit: 255
  end

  add_index "users", ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true, using: :btree
  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree

  add_foreign_key "requests", "tenant_records", column: "comp_id"
  add_foreign_key "requests", "users", column: "initiator_id"
  add_foreign_key "requests", "users", column: "receiver_id"
end
