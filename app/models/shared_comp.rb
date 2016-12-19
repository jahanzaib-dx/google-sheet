class SharedComp < ActiveRecord::Base

  belongs_to :tenant_record, foreign_key: :comp_id
  belongs_to :sale_record, foreign_key: :comp_id
  belongs_to :user, foreign_key: :agent_id

end
