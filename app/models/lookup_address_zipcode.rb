class LookupAddressZipcode < ActiveRecord::Base
  # attr_accessible :name
  has_and_belongs_to_many :tenant_records

  # sets up location as a geometric coordinate
  GEO_FACTORY = RGeo::Geographic.simple_mercator_factory
  #set_rgeo_factory_for_column(:location, GEO_FACTORY.projection_factory)

  # To use geographic (lat/lon) coordinates, convert them using
  # the wrapper factory.
  def latlon
    GEO_FACTORY.unproject(self.location)
  end

  # converts lat,lon to projected values
  # Use this to store lat,lon properly,
  # the db stores projected values which is not lat/lon
  def set_latlon(lat, lon)
    self.location = GEO_FACTORY.project(GEO_FACTORY.point(lat,lon))
  end

  private
  def assign_latlon
    #Remove comment for production
    #GeocodeWorker.perform_async(self.id)
  end
end
