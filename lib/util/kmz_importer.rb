module KmzImporter
  require 'zip/zipfilesystem'

  def self.run
    office_id = Office.find_by_name("San Diego").id
    @area_names = Array.new
    Zip::ZipFile.open("db/data/san-diego-maps.kmz") do |zipfile|
      zipfile.each do |file|
        xml = Nokogiri::XML.parse(file.get_input_stream)

        xml.xpath(".//namespace:Placemark//namespace:name", 'namespace' => 'http://www.opengis.net/kml/2.2' ).each_with_index do |node, i|
          @area_name = node.children.to_s

          coord_node = node.parent.search("coordinates")
          @lat = ""
          @lon = ""
          coord_node.children.first.to_s.split(",0").each do |coord|
            latlon = coord.strip.split(",")
            if latlon[0].nil? || latlon[1].nil?
            else
              @lon += latlon[0] + ','
              @lat += latlon[1] + ','
            end
          end
          m = Map.create(latitude: @lat.chop!, longitude: @lon.chop!, mode: "Polygon", name: @area_name)
          m.office_id = office_id
          m.save

        end
      end
    end
  end

end
