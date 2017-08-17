class OpexMarket < ActiveRecord::Base

  # attr_accessible :name, :code

  has_one :market_expense
  belongs_to :property_type

  def self.opex_market_list(property_type_id)
    where("property_type_id = ?", property_type_id).select('id, name')
  end
end
