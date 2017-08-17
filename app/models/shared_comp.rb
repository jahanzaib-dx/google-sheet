class SharedComp < ActiveRecord::Base

  belongs_to :tenant_record, foreign_key: :comp_id
  belongs_to :sale_record, foreign_key: :comp_id
  belongs_to :user, foreign_key: :agent_id
  
  scope :with_unlock_feild, ->(user_id,comp_type) { where("receiver_id = #{user_id} AND comp_requests.comp_type='#{comp_type}'", user_id ).all }
  
  ##has_many :comp_unlock_field, foreign_key: :shared_comp_id
  
  ## initiator_id(activity_log) == agent_id(comp_share)
  
  has_many :comp_unlock_field, dependent: :destroy
  
  def self.getUnlockData activity
    
    unlockData = SharedComp.select('comp_unlock_fields.id,comp_unlock_fields.field_name').
    where("comp_id = ? AND agent_id = ? AND comp_type = ? ", activity.comp_id,activity.initiator_id,activity.comptype ).
    joins(:comp_unlock_field).all.map{ |comp|
      comp.field_name
    }       
    # unlockData = SharedComp.select('comp_unlock_fields.id,comp_unlock_fields.field_name').
    # where("comp_id = ? AND agent_id = ? AND comp_type = ? ", activity.comp_id,activity.receiver_id,activity.comptype ).
    # joins(:comp_unlock_field).all.map{ |comp|
      # comp.field_name
    # }
    
    unlockData
  end

end
