class SteppedRent < ActiveRecord::Base
  acts_as_paranoid
  belongs_to :tenant_record
  ###attr_accessible :tenant_record_id, :order, :months, :cost_per_month

  validates_numericality_of :months, :cost_per_month

end
