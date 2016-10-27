class ImportLog < ActiveRecord::Base

  belongs_to :tenant_record_import
  belongs_to :office
  belongs_to :tenant_record
  #attr_accessible :tenant_record_import_id, :office_id, :tenant_record_id


end
