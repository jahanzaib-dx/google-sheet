class CompRequest < ActiveRecord::Base

  #belongs_to :tenant_record, foreign_key: :comp_id
  belongs_to :initiated_by, class_name: 'User', foreign_key: :initiator_id
  belongs_to :received_by, class_name: 'User', foreign_key: :receiver_id

end
