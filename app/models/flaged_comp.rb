class FlagedComp < ActiveRecord::Base
  belongs_to :user
  belongs_to :tenant_record, :foreign_key => :comp_id
end
