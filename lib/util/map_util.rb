module MapUtil
  def self.single_comp_map_image(latitude, longitude, zoom)
    root_url = "http://engine.tenantrex.com"
    "http://maps.googleapis.com/maps/api/staticmap?zoom=#{zoom}&size=460x135&maptype=roadmap
    &markers=scale:2|icon:#{root_url}/assets/tenantrex-marker.png|#{latitude},#{longitude}
    &scale=2".gsub(/\s+/,'')
  end

  # Reference: http://jeffjason.com/2011/12/google-maps-radius-to-zoom/
  def self.map_with_radius_image(radius, latitude, longitude)
    root_url = "http://engine.tenantrex.com"
    "http://maps.googleapis.com/maps/api/staticmap?
    zoom=#{((14 - Math.log(Float(radius)) / Math.log(2)).to_i) - 3}&size=455x135&scale=2&maptype=roadmap&markers=scale:2|icon:#{root_url}/assets/tenantrex-marker.png|
        #{latitude.split(',').first},#{longitude.split(',').first}&
        #{GoogleStaticMapsHelper::Path.new(:color => '0x00000000', :fillcolor => :red,
                                           :points => GoogleStaticMapsHelper::Marker.new(
                                               :lat => latitude.split(',').first,
                                               :lng => longitude.split(',').first)
                                           .endpoints_for_circle_with_radius(MathUtil.roundup(radius.to_i * 1609))).url_params}"
    .gsub(/\s+/,'')
  end

  def self.multiple_comp_map_image(comps, dimensions, radius = 1)
    sum_lats = 0
    sum_longs = 0

    comps.each do |x|
      sum_lats = sum_lats + x.latitude
      sum_longs = sum_longs + x.longitude
    end

    "http://maps.googleapis.com/maps/api/staticmap?
        center=#{sum_lats / comps.length},#{sum_longs / comps.length}&size=#{dimensions}&scale=2&
        maptype=roadmap&markers=scale:2|icon:http://goo.gl/1hZ8YO#{ comps.slice(0..84).collect { |x| "|
        #{x.latitude.round(4)},#{x.longitude.round(4)}" }.join}"
    .gsub(/\s+/,'')
  end
end