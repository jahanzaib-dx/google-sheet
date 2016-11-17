class CustomRecord < ActiveRecord::Base

  # attr_accessible :is_existing_data_set, :is_geo_coded, :name,
  #                 :address1, :city, :state, :latitude, :longitude, :zipcode, :zipcode_plus,
  #                 :custom_record_properties_attributes



  has_many :custom_record_properties
  accepts_nested_attributes_for :custom_record_properties

  before_save :default_values
  before_validation :default_values



  def self.get_custom_records
    select('id, name')
  end

  private
  def default_values
    self.user_id = User.current_user.id

    # this true keeps validation from failing...
    true
  end

end
