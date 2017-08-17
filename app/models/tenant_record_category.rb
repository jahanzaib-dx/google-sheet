class TenantRecordCategory < ActiveRecord::Base
  # attr_accessible :name

  has_many :tenant_record_category_fields
  # has_many :custom_report_headers
end
