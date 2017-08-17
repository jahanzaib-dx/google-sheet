class PropertyType < ActiveRecord::Base

  # attr_accessible :name

  has_many :opex_markets


  def self.get_property_type(id)
    find(id)
  end

  def self.property_type_list
    self.pluck('name')

  end
end
