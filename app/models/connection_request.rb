class ConnectionRequest < ActiveRecord::Base

  belongs_to :sender, class_name: 'User'
  belongs_to :receiver, class_name: 'User', foreign_key: 'agent_id'

end
