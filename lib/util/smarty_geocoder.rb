class SmartyGeocoder
  def self.smarty_streets_geocoder tenant_record
    # HTTParty.get("https://api.smartystreets.com/street-address/",
    #              header: { 'ContentType' => 'application/json' },
    #              query: {
    #                'auth-id' => "f26050c3-c2ab-4626-8791-fd52c32a6e0a",
    #                'auth-token' => "GyTKGL1Zc22vtQrA6o/7nLmR19XrwOCi0Gv8IeKNN8w6lPkORdtYuM47OvseKAt+aMY7G4P+YcAcgRNSGJpK2w==",
    #                :street => tenant_record.address1,
    #                :street2 => (tenant_record.suite ? tenant_record.suite : nil),
    #                :city => tenant_record.city,
    #                :state => tenant_record.state,
    #                :zipcode => tenant_record.zipcode,
    #                :candidates => 3
    #              }
    #             )
    self.smarty_streets_geocoder_address({
        :address1 => tenant_record.address1,
        :address2 => (tenant_record.suite ? tenant_record.suite : nil),
        :city => tenant_record.city,
        :state => tenant_record.state,
        :zipcode => tenant_record.zipcode
      })
  end

  def self.smarty_streets_geocoder_address property
    HTTParty.get("https://api.smartystreets.com/street-address/",
                 header: { 'ContentType' => 'application/json' },
                 query: {
                   'auth-id' => "f26050c3-c2ab-4626-8791-fd52c32a6e0a",
                   'auth-token' => "GyTKGL1Zc22vtQrA6o/7nLmR19XrwOCi0Gv8IeKNN8w6lPkORdtYuM47OvseKAt+aMY7G4P+YcAcgRNSGJpK2w==",
                   :street => property[:address1],
                   :street2 => property[:address2],
                   :city => property[:city],
                   :state => property[:state],
                   :zipcode => property[:zipcode],
                   :candidates => 3
                 }
                )
  end

  def self.valid_address geos
    # This will check the footer flags and pass through non blocking errors. All errors are in lib/util/smarty_errors.rb
    # A: Corrected ZIP code
    # B: Fixed city/state spelling
    # N: Fixed abbreviations
    # S: Bad secondary address
    # H: Missing secondary number
    if !geos.blank? &&
      (geos[0]['analysis']['dpv_footnotes'] =~ /^AA/ || # Valid address
       geos[0]['analysis']['footnotes'] =~ /[ABNSH]/ ||
       geos[0]['analysis']['footnotes'].nil?)
      true
    else
      false
    end
  end

  def self.add_smarty_notifications trec, geos
    geo_info = []
    geo_addresses = []
    geos.each do |geo|
      if geo["analysis"]["footnotes"]
        geo["analysis"]["footnotes"].split("#").each do |code|
          geo_info << SmartyErrors::FOOTNOTES[code]
        end
      end

      geo_addresses << Hash["full_address" => geo["delivery_line_1"].to_s + " " + geo["delivery_line_2"].to_s + " " + geo["last_line"].to_s,
                            "address1" => smarty_address1(geo),
                            "city" => geo["components"]["city_name"].to_s,
                            "state" => geo["components"]["state_abbreviation"].to_s,
                            "zipcode" => geo["components"]["zipcode"].to_s,
                            "zip4" => geo["components"]["plus4_code"].to_s,
                            "latitude" => geo["metadata"]["latitude"].to_s,
                            "longitude" => geo["metadata"]["longitude"].to_s,
                            "id" => trec.id

      ]
    end
    {"geocode_info" => geo_info, "geocode_addresses" => geo_addresses }
  end

  def self.smarty_address1 geo
    address1 = ""
    address1 += geo["components"]["primary_number"] if geo["components"]["primary_number"]
    address1 += " " + geo["components"]["street_predirection"] if geo["components"]["street_predirection"]
    address1 += " " + geo["components"]["street_name"]if geo["components"]["street_name"]
    address1 += " " + geo["components"]["street_postdirection"]if geo["components"]["street_postdirection"]
    address1 += " " + geo["components"]["street_suffix"] if geo["components"]["street_suffix"]
    address1
  end

  def self.smarty_suite geo
    suite = ""
    suite += geo["components"]["secondary_designator"].to_s + " " if geo["components"]["secondary_designator"]
    suite += geo["components"]["secondary_number"].to_s + " " if geo["components"]["secondary_number"]
    suite
  end
end
