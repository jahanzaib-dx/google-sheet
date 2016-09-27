class TenantRecord < ActiveRecord::Base

  has_many :comp_requests
  belongs_to :user
  has_one :flaged_comp, :foreign_key => :comp_id


  def complete_address
    [address1, city, state, zipcode].join(", ")
  end

end
