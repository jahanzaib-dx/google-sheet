class Market < ActiveRecord::Base
  has_many :learn_more_requests
  # attr_accessible :name, :is_preferred
end

