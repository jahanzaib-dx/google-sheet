class IndustrySicCode < ActiveRecord::Base
  has_many :tenant_records
  # attr_accessible :value, :description, :division, :major_group, :industry_group,
  #   :division_desc, :major_group_desc, :industry_group_desc
end
