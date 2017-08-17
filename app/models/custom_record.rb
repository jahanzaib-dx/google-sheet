class CustomRecord < ActiveRecord::Base

  # attr_accessible :is_existing_data_set, :is_geo_coded, :name,
  #                 :address1, :city, :state, :latitude, :longitude, :zipcode, :zipcode_plus,
  #                 :custom_record_properties_attributes



  has_many :custom_record_properties
  accepts_nested_attributes_for :custom_record_properties

  belongs_to :user

  before_save :default_values
  before_validation :default_values


  def rows
    record_rows = {}
    custom_record_properties.each do |property|
      row_id = property.row_id
      col_name = property.key
      if property.visible
        if record_rows.has_key? row_id
          record_rows[row_id][col_name] = property.value
        else
          record_rows.merge!( {row_id => {col_name => property.value } } )
        end
      end
    end
    record_rows
  end

  def get_next_row_number
    obj = CustomRecordProperty.where({custom_record_id: id}).order('row_id DESC').first
    if obj.nil?
      1
    else
      obj.row_id+1
    end
  end


  def self.get_custom_records
    select('id, name').where({user_id: User.current_user.id})
  end

  private
  def default_values
    self.user_id ||= User.current_user.id

    # this true keeps validation from failing...
    true
  end

end
