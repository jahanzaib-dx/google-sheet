class CustomRecord < ActiveRecord::Base

  # attr_accessible :is_existing_data_set, :is_geo_coded, :name,
  #                 :address1, :city, :state, :latitude, :longitude, :zipcode, :zipcode_plus,
  #                 :custom_record_properties_attributes



  has_many :custom_record_properties
  accepts_nested_attributes_for :custom_record_properties


  def self.get_custom_records
    select('id, name')
  end
end
