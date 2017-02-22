require 'uri'

VALIDATION_ERRORS = {:street_number => "Address not found",
                     :city => "City not found",
                     :state => "State not found",
                     :zipcode => "Zipcode not found"
}

module GoogleGeocoder

  def geocode_address(tenant_record, address_only = false)
    get_address_by_geocode({
                               :address1 => tenant_record.address1,
                               :city => tenant_record.city,
                               :state => tenant_record.state,
                               :country=> tenant_record.country,
                               :zipcode => tenant_record.zipcode
                           },
                           address_only)
  end

  def get_address_by_geocode(tenant_hash, address_only)
    combined_fields = address_only ? ("#{tenant_hash[:address1]}, #{tenant_hash[:city]}") :
        ("#{tenant_hash[:address1]}, #{tenant_hash[:city]}, #{tenant_hash[:state]}, #{tenant_hash[:country]}, #{(tenant_hash[:zipcode].present? ? tenant_hash[:zipcode] : '')}")
    #("#{tenant_hash[:address1]}, #{tenant_hash[:city]}, #{tenant_hash[:state]}, #{tenant_hash[:zipcode]}")
    uri = URI.encode("https://maps.googleapis.com/maps/api/geocode/json?address=#{combined_fields}&key=AIzaSyAiX-5uM4E2QtEVLOhyfti8YaomGndX240")

    Rails.logger.debug "****************************************************************************"
    Rails.logger.debug "GEOCODE URL: #{uri}"

    HTTParty.get(uri)
  end

  def is_valid_address?(tenant_record, geocode)
    (tenant_record.address1.present? && tenant_record.city.present? &&
        tenant_record.state.present?) && validate_address_types(geocode) ? true : false
  end

  def validate_address_types(geocode)
    case geocode[:address_type]
      when 'premise'
        (geocode[:city].present? &&
            geocode[:state].present? && geocode[:zipcode].present?) ? true : false
      when 'route'
        (geocode[:address1].present? && geocode[:city].present? &&
            geocode[:state].present? && geocode[:zipcode].present?) ? true : false
      else
        # street_address in focus
        (geocode[:address1].present? && geocode[:city].present? &&
            geocode[:state].present? && geocode[:zipcode].present? &&
            geocode[:street_number].present?) ? true : false
    end
  end

  def parse_geocode_response(geocode_instance)
    final_address_hash = []
    begin
      if geocode_instance.present?
        geocode_instance.each do |record|
          result = Hash.new
          record.each do |key, array|
            case key
              when 'address_components'
                array.each do |element|
                  attr_type = element['types'].first
                  result[:street_number] = element['short_name'] if attr_type == 'street_number'
                  result[:address1] = "#{result[:street_number]} #{element['short_name']}" if attr_type == 'route'
                  result[:city] = element['long_name'] if attr_type == 'neighborhood' || attr_type == 'locality'
                  result[:state] = element['short_name'] if attr_type == 'administrative_area_level_1'
                  result[:zipcode] = element['long_name'] if attr_type == 'postal_code'
                end
              when 'geometry'
                result[:latitude] = array['location']['lat']
                result[:longitude] = array['location']['lng']
              when 'formatted_address'
                result[:full_address] = array
              when 'types'
                result[:address_type] = array.first
            end
          end
          final_address_hash << result
        end
      end
    rescue => exception
      logger.info('Something went wrong with parse_geocode_response.')
    end
    final_address_hash
  end

  def validate_address_google(trec, tr_geocode_status = 'false', address_only = false)
    geocode_response = geocode_address(trec, address_only)
    parsed_result = parse_geocode_response(geocode_response["results"])
    parsed_result = get_unique_hash(parsed_result)
    if !parsed_result.empty? and !parsed_result[0][:city].downcase.strip.empty?
      if (parsed_result.count > 1 && tr_geocode_status == 'false') ||
          (parsed_result.count == 1 && parsed_result[0][:city].downcase.strip != trec[:city].downcase.strip)
        { valid: false, errors: add_city_suggestions(parsed_result) }
      else
        result_hash = parsed_result.first
        is_valid = is_valid_address?(trec, result_hash)
        if result_hash.blank? || !is_valid
          { valid: false,
            errors: {
                geocode_info: "There was an error with this address. Please check the address fields and submit again",
                tenant_record: {
                    :address1 => ['Address not found.'],
                    :city => ['Address not found.'],
                    :state => ['Address not found.']
                }
            }
          }
        else
          valid = { valid: true, errors: {} }

          valid[:updates] = {
              address1: result_hash[:address1],
              city: result_hash[:city],
              state: result_hash[:state],
              zipcode: result_hash[:zipcode],
              zipcode_plus: nil,
              latitude: result_hash[:latitude],
              longitude:result_hash[:longitude] } if geocode_response['results'].first.present?
          valid
        end
      end
    else
      { valid: false,
        errors: {
            geocode_info: "There was an error with this address. Please check the address fields and submit again",
            tenant_record: {
                :address1 => ['Address not found.'],
                :city => ['Address not found.'],
                :state => ['Address not found.']
            }
        }
      }
    end
  end

  def add_city_suggestions(parsed_city_list)
    geo_info = []
    geo_addresses = []

    geo_info << 'Please select valid city from drop down.'
    if parsed_city_list.present?
      parsed_city_list.each do |record|
        geo_addresses << {:full_address => record[:full_address].to_s,
                          :address1 => record[:address1].to_s,
                          :city => record[:city].to_s,
                          :state => record[:state].to_s,
                          :zipcode => record[:zipcode].to_s,
                          :zip4 => nil,
                          :latitude => record[:latitude].to_s,
                          :longitude => record[:longitude].to_s}
      end
    end
    { geocode_info: geo_info, geocode_addresses: geo_addresses.uniq{|addr| addr[:city]},
      tenant_record: {
          :city => ['Incorrect city.']
      }
    }

  end

  def add_notifications(trec, parsed_hash)
    geo_info = []
    geo_addresses = []

    parsed_hash.each do |hash|
      VALIDATION_ERRORS.each do |key, value|
        geo_info << value unless hash.include?(:key)
      end
      geo_addresses << {:full_address => hash[:full_address].to_s,
                        :address1 => hash[:address1].to_s,
                        :city => hash[:city].to_s,
                        :state => hash[:state].to_s,
                        :zipcode => hash[:zipcode].to_s,
                        :zip4 => nil,
                        :latitude => hash[:latitude].to_s,
                        :longitude => hash[:longitude].to_s,
                        :id => trec.id}

    end
    { :geocode_info => geo_info, :geocode_addresses => geo_addresses }
  end

  def office_geocode(office)
    result = validate_address_google(office)
    if result.has_key? :coords
      office.latitude = result[:coords][:latitude]
      office.longitude = result[:coords][:longitude]
    elsif result.has_key? :errors and result[:errors].has_key? :geocode_info and result[:errors][:geocode_info].include? 'Please select valid city from drop down.'
      office.latitude = result[:errors][:geocode_addresses][0][:latitude]
      office.longitude = result[:errors][:geocode_addresses][0][:longitude]
    elsif result.has_key? :updates
      office.latitude = result[:updates][:latitude]
      office.longitude = result[:updates][:longitude]
    end
    office
  end

  def get_unique_hash(parsed_result)
    arr = []
    parsed_result.each do |hash|
      if arr.present?
        is_present = false
        i = 0
        while i < arr.length && !is_present do
          is_present = true if arr[i][:city].downcase == hash[:city].downcase
          i += 1
        end
        arr << hash unless is_present
      else
        arr << hash
      end
    end
    arr
  end

  def get_unique_hash_using_standard_attributes(parsed_result, tenant_record)
    arr = []
    filtered_list = []
    parsed_result.each do |hash|
      if (hash[:address1].present? && hash[:address_type] != 'premise') || (parsed_result.length == 1)
        if (tenant_record.zipcode.blank? || (tenant_record.zipcode.present? && tenant_record.zipcode.to_s == hash[:zipcode]))
          filtered_list << hash
        end
      end
    end
    if filtered_list.length > 1
      filtered_list.each do |hash|
        if arr.present?
          is_present = false
          i = 0
          while i < arr.length && !is_present do
            is_present = true if exact_match(arr[i], hash)
            i += 1
          end
          arr << hash unless is_present
        else
          arr << hash unless hash[:address_type] == 'premise'
        end
      end
    else
      arr = filtered_list
    end
    arr
  end

  def exact_match(arr, hash)
    flag = true
    if arr[:address_type] == 'street_address' && hash[:address_type] == 'street_address'
      flag = ((arr[:street_number].downcase == hash[:street_number].downcase &&
          arr[:city].downcase == hash[:city].downcase && arr[:state].downcase == hash[:state].downcase &&
          arr[:zipcode].downcase == hash[:zipcode].downcase) ? true : false) rescue true
    end
    flag
  end
end