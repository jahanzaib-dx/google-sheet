class TenantRecord < ActiveRecord::Base

  has_many :comp_requests
  belongs_to :user


  def complete_address
    [address1, city, state, zipcode].join(", ")
  end

end
