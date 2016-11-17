class ImportRecord < ActiveRecord::Base
  belongs_to :tenant_record_import
  #attr_accessible :tenant_record_import_id, :data
  #serialize :data, ActiveRecord::Coders::NestedHstore rails 4 provides HStore type support
  #serialize :record_errors, ActiveRecord::Coders::NestedHstore rails 4 provides HStore type support


  def data
    d = super
    d.with_indifferent_access if d
  end
  def record_errors
    re = super
    re.with_indifferent_access if re
  end

end
