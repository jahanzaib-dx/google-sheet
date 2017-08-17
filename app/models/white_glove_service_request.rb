class WhiteGloveServiceRequest < ActiveRecord::Base
  belongs_to :user
  belongs_to :tenant_record
end
