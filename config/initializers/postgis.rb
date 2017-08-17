RGeo::ActiveRecord::SpatialFactoryStore.instance.tap do |config|

  # By default, use the GEOS implementation for spatial columns.
  #config.default = RGeo::Geos.factory_generator

  # But use a geographic implementation for point columns.
  config.register(RGeo::Geographic.simple_mercator_factory(srid: 3785).projection_factory, geo_type: "point")
end