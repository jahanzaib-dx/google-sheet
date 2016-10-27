class TenantRecordCategoryField < ActiveRecord::Base
  # attr_accessible :label_name, :order, :tenant_record_category_id, :tenant_record_field

  # has_many :custom_report_header_fields
  belongs_to :tenant_record_category
end
