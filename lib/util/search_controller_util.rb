module SearchControllerUtil

  def scope_records_by_params(params, user)
    if (params['analytics_view'])
      # Analytics needs access to every attribute of a comp, don't return a protected view
      tenant_records = TenantRecord.scoped
      tenant_records = user.account.office.tenant_records.scoped if !user.has_trex_admin?
    ###elsif (user.has_trex_admin?)
      ###tenant_records = TenantRecord.protect_view(user).scoped
      ###tenant_records = TenantRecord.summary.scoped if params['summary']
    else
      tenant_records = scope_protect_view_office_user(params, user)
      tenant_records = user.account.office.tenant_records.summary.scoped if params['summary']
    end

    if (!params['disable_tenant_record_id'].blank?)
      tenant_records = tenant_records.where("tenant_records.id NOT IN (?)", params['disable_tenant_record_id'])
    end

    if (!params['disable_comp_type'].blank?)
      tenant_records = tenant_records.where("tenant_records.comp_type NOT IN (?)", params['disable_comp_type'])
    end

    if (!params['disable_view_type'].blank?)
      if user.has_admin?
        tenant_records = tenant_records.where("tenant_records.view_type NOT IN (?)", params['disable_view_type'])
      else
        tenant_records = tenant_records.where("(CASE WHEN(tenant_records.view_type = 'private') THEN 'private' WHEN (" + user.account.office_id.to_s + " <> tenant_records.office_id) THEN 'network' ELSE tenant_records.view_type END) NOT IN (?)", params['disable_view_type'])
      end
    end

    if (!params['disable_network'].blank? && !user.account.office_id.nil?)
      #tenant_records = tenant_records.where("IF(tenant_records.view_type = 'private', 'private', IF(" + user.account.office_id.to_s + " <> tenant_records.office_id, 'network', tenant_records.view_type)) <> 'network'", params['disable_view_type'])
      tenant_records = tenant_records.where("tenant_records.office_id = ?", user.account.office_id)
    end

    if (!params['industry_type'].blank?)
      tenant_records = tenant_records.where("tenant_records.industry_type like ?", params['industry_type'])
    end

    if (!params['lease_type'].blank?)
      tenant_records = tenant_records.where("tenant_records.lease_type = ?", params['lease_type'].to_s.strip)
    end

    if (!params['location_type'].blank?)
      tenant_records = tenant_records.where("tenant_records.location_type IN (?)", params['location_type'])
    end

    if (!params['property_type'].blank?)
      tenant_records = tenant_records.where("tenant_records.property_type IN (?)", params['property_type'])
    end
    
    if (!params['submarket'].blank?)
      tenant_records = tenant_records.where("Lower(tenant_records.submarket) IN (?)", params['submarket'])
    end

    if (!params['class_type'].blank?)
      tenant_records = tenant_records.where("tenant_records.class_type IN (?)", params['class_type'])
    end


    if (!params['sq_ft_range'].blank?)
        size_arr = params['sq_ft_range'].split('-')

        if (!size_arr[0].blank?)
          tenant_records = tenant_records.where("tenant_records.size >= ?", size_arr[0].to_f)
        end

        if (!size_arr[1].blank?)
          tenant_records = tenant_records.where("tenant_records.size <= ?", size_arr[1].to_f)
        end
    end

    if (!params['zipcode_or_city'].blank? && !params['zipcode_or_city_value'].blank?)
      logger.debug params['zipcode_or_city_value']
      if (params['zipcode_or_city'] == 'zipcode')
        tenant_records = tenant_records.where("tenant_records.zipcode = ?", params['zipcode_or_city_value'])
      else
        tenant_records = tenant_records.where("tenant_records.city = ?", params['zipcode_or_city_value'])
      end
    end

    if (!params['lease_commencement_date_min'].blank? && !params['lease_commencement_date_max'].blank?)
      min_date = Date.strptime(params['lease_commencement_date_min'], '%m/%Y')
      max_date = Date.strptime(params['lease_commencement_date_max'], '%m/%Y') + 1.month - 1.day
      tenant_records = tenant_records.where(:lease_commencement_date => min_date..max_date)
    elsif (!params['lease_commencement_date_min'].blank?)
      min_date = Date.strptime(params['lease_commencement_date_min'], '%m/%Y')
      tenant_records = tenant_records.where('lease_commencement_date >= ?', min_date)
    elsif (!params['lease_commencement_date_max'].blank?)
      max_date = Date.strptime(params['lease_commencement_date_max'], '%m/%Y') + 1.month - 1.day
      tenant_records = tenant_records.where('lease_commencement_date < ?', max_date)
    end

    if (!params['latitude'].blank? && !params['longitude'].blank?)
      params['latitude'] = params['latitude'].join(',')   if params['latitude'].is_a? Array
      params['longitude'] = params['longitude'].join(',') if params['longitude'].is_a? Array
      $min_latitude = params['latitude'].split(',').min
      $max_latitude = params['latitude'].split(',').max
      $min_longitude = params['longitude'].split(',').min
      $max_longitude = params['longitude'].split(',').max
      
      if (!params['connection'].blank? )
        ##tenant_records = tenant_records.ownership_lease.where("ownerships.account_id = ?" , params['connection'])
        tenant_records = tenant_records.where("user_id = ?" , params['connection'])
        else
        @connections = Connection.all_connection_ids(current_user)
        ##p @con3
        tenant_records = tenant_records.where("user_id IN (?) OR user_id=?" , @connections.to_a,current_user.id)

        ##tenant_records = tenant_records.where("user_id = ?" , params['connection'])
      end
      
      tenant_records = tenant_records.where("(tenant_records.latitude > ? AND tenant_records.latitude < ? AND tenant_records.longitude > ? AND tenant_records.longitude < ?)", $min_latitude.to_f, $max_latitude.to_f, $max_longitude.to_f, $min_longitude.to_f)
    end


    #begin
      # Using SOLR instead
      #$found_id = []
      #$q = URI::encode("^"+params['q'])
      #uri = URI("http://67.23.43.218:8080/solr/collection1/select?q=address1%3A%22" + $q.to_s + "%22&rows=1000&df=address1&wt=json");
      #res = Net::HTTP.get_response(uri)
      #if (res.code == "200" && !res.body.blank?)
      #  json = JSON.parse res.body
      #  json['response']['docs'].each do |k|
      #    $found_id.push(k['id'].to_i)
      #  end
      #end
      #tenant_records = tenant_records.where("id IN (?)", $found_id)
    #rescue Exception => $e
    #  logger.debug "Unable to get solr request: " + $e.message
    #end
    # TODO look at code, fixe to use solr? NOT USING SOLR, JUST MYSQL
    unless params['latitude'].present? and params['longitude'].present?
      clause = if params['address1'].present? and params['zipcode'].present? and (params['search_type'] == 'address_zipcode')
                 { :where => "LOWER(tenant_records.address1) = :address1 AND tenant_records.zipcode = :zipcode",
                   :params => { :address1 => params['address1'].downcase, :zipcode => params['zipcode'].to_s }
                 }
               elsif params['q'].present?
                 if params['search_type'].present?
                   case params['search_type']
                   when 'company'
                     {
                       :where => "LOWER(tenant_records.company) = :company",
                       :params => { :company => params['q'].downcase }
                     }
                   when 'submarket'
                     {
                       :where => "LOWER(tenant_records.submarket) = :submarket",
                       :params => { :submarket => params['q'].downcase }
                     }
                   when 'property_name'
                     {
                       :where => "LOWER(tenant_records.property_name) = :property_name",
                       :params => { :property_name => params['q'].downcase }
                     }
                   else
                     {
                       :where => "LOWER(tenant_records.address1) LIKE :address1",
                       :params => { :address1 => "#{params['address1'].gsub(/[\.\s]/,'%')}%".downcase }
                     }
                    end
                 else
                   {
                     :where => "LOWER(tenant_records.address1) LIKE :address1",
                     :params => { :address1 => "#{params['q'].gsub(/[\.\s]/,'%')}%".downcase }
                   }
                 end
               elsif params['term'].present?
                 {
                   :where => "LOWER(tenant_records.address1) LIKE :address1",
                   :params => { :address1 => "#{params['term'].gsub(/[\.\s]/,'%')}%".downcase }
                 }
               end
               
               
               # if clause.nil?
                 # clause = {
                   # :where => "1=:a",
                   # :params => { :a => 1  }
                 # }
               # end
                 
                 


      if (!params['connection'].blank? )
        ##tenant_records = tenant_records.where("user_id = ?" , params['connection'])
        tenant_records = tenant_records.where("user_id IN (?) OR user_id=?" , params['connection'],current_user.id)
        connections_ids = params['connection']
      else
        @connections = Connection.all_connection_ids(current_user)
        ##p @con3
        tenant_records = tenant_records.where("user_id IN (?) OR user_id=?" , @connections.to_a,current_user.id)
        connections_ids = @connections.join(",")
        ##tenant_records = tenant_records.where("user_id = ?" , params['connection'])
      end
      
      
      
query = "
select z.id,z.address1,z.user_id from (
select y.id,y.address1,y.user_id from tenant_records y
            where (select count(*) from tenant_records dt
            where  y.address1 = dt.address1
            and (dt.user_id in (#{connections_ids}) or dt.user_id = #{current_user.id})
            ) > 1 
and (y.user_id in (#{connections_ids}) or y.user_id=#{current_user.id}) order by y.address1 
) as z where z.user_id = #{current_user.id}
"

    dup_tenant_records = TenantRecord.find_by_sql(query)
    
    
    
      ##dup_tenant_records = TenantRecord.where("" , @connections.to_a,current_user.id)
      
      
      tenant_records = tenant_records
      .joins("left join (select * from activity_logs where comptype = 'lease' and initiator_id in (#{current_user.id})) as a on tenant_records.id=a.comp_id")
      .joins("left join (select * from comp_requests where comp_type = 'lease' and initiator_id in (#{current_user.id})) as c on tenant_records.id=c.comp_id")
      .order("address1,
        CASE 
          
          WHEN a.status is null AND c.comp_id is null THEN '1'
          
          WHEN c.comp_id > 0 THEN '2'
          
          WHEN a.status = 'full' THEN '3'
          WHEN a.status = 'partial' THEN '4'
          WHEN a.status = 'Rejected' THEN '5'
        
        ELSE a.status END ASC
         
      
        
        ")
      ##.joins("left join (select * from activity_logs where receiver_id!=#{current_user.id} and receiver_id not in (#{connections_ids}) ) as a on tenant_records.id=a.comp_id")
      ##.joins("left join (select * from comp_requests where receiver_id!=#{current_user.id} and receiver_id not in (#{connections_ids})) as c on tenant_records.id=c.comp_id")
      
        
        #hide child
        #####tenant_records = tenant_records.where("tenant_records.id not in (select child_comp from activity_logs where comptype = 'lease' and ( receiver_id in (#{current_user.id})  ) and child_comp > 0)")
        #hide parent
        #####tenant_records = tenant_records.where("tenant_records.id not in (select comp_id from activity_logs where comptype = 'lease' and ( initiator_id in (#{current_user.id})   )  and status = 'full_owner')")
        
        #####tenant_records = tenant_records.where("tenant_records.id not in (select comp_id from activity_logs where comptype = 'lease' and ( initiator_id in (#{current_user.id})   )  and status = 'full_owner')")
        
        #####tenant_records = tenant_records.where("tenant_records.id not in (select id from tenant_records where user_id !=#{current_user.id} and master_id in (select master_id from activity_logs where comptype = 'lease' and ( initiator_id in (#{current_user.id})   )  and status = 'full_owner') ) ")
        ##tenant_records = tenant_records.where("tenant_records.id not in (select id from tenant_records where user_id !=#{current_user.id} and master_id in (select comp_id from activity_logs where comptype = 'lease' and ( initiator_id in (#{current_user.id})   )  and status = 'full_owner') as al ) ")
        
        ##select master_id from activity_logs where ( initiator_id in (#{current_user.id})  )  and status = 'full_owner' and master_id>0)
        
        ##tenant_records = tenant_records.where("( tenant_records.id in (select child_comp from activity_logs where ( initiator_id in (#{current_user.id})  )  and status = 'full_owner'))")
        
        ###tenant_records = tenant_records.where("tenant_records.id in (select comp_id from activity_logs where ( initiator_id in (#{current_user.id})  )  and status = 'full_owner')")







    tenant_records = tenant_records.where("tenant_records.id not in (select id from tenant_records as tr where user_id!=#{current_user.id} and tr.address1 in (?)) ",dup_tenant_records.join(","))
    
    ##tenant_records = tenant_records.where("tenant_records.address1 (not in (?)) ",dup_tenant_records.join(","))
    
    



	  tenant_records = tenant_records.where(clause[:where], clause[:params])
    end

    tenant_records
  end

  def get_sixsigma(id, field, avg, tile)
    TenantRecord.six_sigma(field, avg, tile).where('id = ?', id).first
  end

  def scope_address_only_office_user(params, user)
    user.account.office.tenant_records.address_only(current_user.account.office_id).scoped
  end

  def scope_protect_view_office_user(params, user)
    ####user.account.office.tenant_records.protect_view(user).scoped
	TenantRecord.protect_view(user).all
  end

  def sale_scope_protect_view_office_user(params, user)
    ####user.account.office.tenant_records.protect_view(user).scoped
    SaleRecord.protect_view(user).all
  end

  def update_sic_codes
    begin
      sic_code_path = "#{Rails.root}/lib/SIC-Codes"
      Rails.logger.info("Updating SIC codes submodule from \"https://github.com/bigspotteddog/SIC-Codes.git\" ===== " +
                       %x(cd #{sic_code_path};git pull origin master))

      current_division = ""
      current_major_group = ""
      current_industry_group = ""

      current_division_desc = ""
      current_major_group_desc = ""
      current_industry_group_desc = ""

      CSV.foreach(sic_code_path + "/sic_codes.csv", headers: true, :col_sep => "\t") do |row|

        if row["Division/SIC"] =~ /[A-Z]/
          current_division = row["Division/SIC"]
          current_division_desc = row["Description"]

        elsif row["Division/SIC"].last(2) == '00'
          current_major_group = row["Division/SIC"].chop.chop
          current_major_group_desc = row["Description"]

        elsif row["Division/SIC"].last == '0'
          current_industry_group = row["Division/SIC"].chop
          current_industry_group_desc = row["Description"]

        else
          sic = IndustrySicCode.find_or_initialize_by_value(row["Division/SIC"])
          sic.update_attributes(description: row["Description"],
                                division: current_division,
                                division_desc: current_division_desc,
                                major_group: current_major_group,
                                major_group_desc: current_major_group_desc,
                                industry_group: current_industry_group,
                                industry_group_desc: current_industry_group_desc)
        end
      end
    rescue => e
      Rails.logger.error "Error updating SIC Codes" + e.to_s
    end

  end

  def toRad(v)
    v * Math::PI / 180
  end

  def toDeg(v)
    v * 180 / Math::PI
  end

  def apply_radius(radius, lat, long)
    latitude = [lat]
    longitude = [long]
    d = radius.to_f / 1.60934 # in miles, 6371km is the earths radius
    earth_radius = 3959
    # Bearings
    brngs = [0, 90, 180, 270]
    brngs.each do |b|
      brng = toRad(b)
      lat1 = toRad(lat)
      lon1 = toRad(long)
      lat2 = Math.asin(Math.sin(lat1) * Math.cos(d/earth_radius) + Math.cos(lat1) * Math.sin(d/earth_radius) * Math.cos(brng))
      lon2 = lon1 + Math.atan2(Math.sin(brng) * Math.sin(d/earth_radius) * Math.cos(lat1), Math.cos(d/earth_radius) - Math.sin(lat1) * Math.sin(lat2))
      lon2 = (lon2 + 3 * Math::PI) % (2 * Math::PI) - Math::PI
      lat2 = toDeg(lat2)
      lon2 = toDeg(lon2)
      latitude.push(lat2)
      longitude.push(lon2)
    end
    [latitude, longitude]
  end




  def sales_scope_records_by_params(params, user)
    if (params['analytics_view'])
      # Analytics needs access to every attribute of a comp, don't return a protected view
      tenant_records = TenantRecord.scoped
      tenant_records = user.account.office.tenant_records.scoped if !user.has_trex_admin?
      ###elsif (user.has_trex_admin?)
      ###tenant_records = TenantRecord.protect_view(user).scoped
      ###tenant_records = TenantRecord.summary.scoped if params['summary']
    else
      tenant_records = sale_scope_protect_view_office_user(params, user)
      tenant_records = user.account.office.tenant_records.summary.scoped if params['summary']
    end

    # if (!params['disable_tenant_record_id'].blank?)
    #   tenant_records = tenant_records.where("tenant_records.id NOT IN (?)", params['disable_tenant_record_id'])
    # end
    #
    # if (!params['disable_comp_type'].blank?)
    #   tenant_records = tenant_records.where("tenant_records.comp_type NOT IN (?)", params['disable_comp_type'])
    # end

    # if (!params['disable_view_type'].blank?)
    #   if user.has_admin?
    #     tenant_records = tenant_records.where("tenant_records.view_type NOT IN (?)", params['disable_view_type'])
    #   else
    #     tenant_records = tenant_records.where("(CASE WHEN(tenant_records.view_type = 'private') THEN 'private' WHEN (" + user.account.office_id.to_s + " <> tenant_records.office_id) THEN 'network' ELSE tenant_records.view_type END) NOT IN (?)", params['disable_view_type'])
    #   end
    # end

    # if (!params['disable_network'].blank? && !user.account.office_id.nil?)
    #   #tenant_records = tenant_records.where("IF(tenant_records.view_type = 'private', 'private', IF(" + user.account.office_id.to_s + " <> tenant_records.office_id, 'network', tenant_records.view_type)) <> 'network'", params['disable_view_type'])
    #   tenant_records = tenant_records.where("tenant_records.office_id = ?", user.account.office_id)
    # end

    # if (!params['industry_type'].blank?)
    #   tenant_records = tenant_records.where("tenant_records.industry_type like ?", params['industry_type'])
    # end
    #
    # if (!params['lease_type'].blank?)
    #   tenant_records = tenant_records.where("tenant_records.lease_type = ?", params['lease_type'].to_s.strip)
    # end
    #
    # if (!params['location_type'].blank?)
    #   tenant_records = tenant_records.where("tenant_records.location_type IN (?)", params['location_type'])
    # end

    if (!params['property_type'].blank?)
      tenant_records = tenant_records.where("sale_records.property_type IN (?)", params['property_type'])
    end
    
    if (!params['submarket'].blank?)
      tenant_records = tenant_records.where("Lower(sale_records.submarket) IN (?)", params['submarket'])
    end

    if (!params['class_type'].blank?)
      tenant_records = tenant_records.where("sale_records.class_type IN (?)", params['class_type'])
    end

    if (!params['price_min'].blank?)
      tenant_records = tenant_records.where("sale_records.price >= ?", params['price_min'].to_f)
    end

    if (!params['price_max'].blank?)
      tenant_records = tenant_records.where("sale_records.price <= ?", params['price_max'].to_f)
    end

    if (!params['cap_min'].blank?)
      tenant_records = tenant_records.where("sale_records.cap_rate >= ?", params['cap_min'].to_f)
    end

    if (!params['cap_max'].blank?)
      tenant_records = tenant_records.where("sale_records.cap_rate <= ?", params['cap_max'].to_f)
    end


    if (!params['sq_ft_range'].blank?)
      size_arr = params['sq_ft_range'].split('-')

      if (!size_arr[0].blank?)
        tenant_records = tenant_records.where("sale_records.land_size >= ?", size_arr[0].to_f)
      end

      if (!size_arr[1].blank?)
        tenant_records = tenant_records.where("sale_records.land_size <= ?", size_arr[1].to_f)
      end
    end

    # if (!params['zipcode_or_city'].blank? && !params['zipcode_or_city_value'].blank?)
    #   logger.debug params['zipcode_or_city_value']
    #   if (params['zipcode_or_city'] == 'zipcode')
    #     tenant_records = tenant_records.where("tenant_records.zipcode = ?", params['zipcode_or_city_value'])
    #   else
    #     tenant_records = tenant_records.where("tenant_records.city = ?", params['zipcode_or_city_value'])
    #   end
    # end

    if (!params['build_year_min'].blank? && !params['build_year_max'].blank?)
      min_date = Date.strptime(params['build_year_min'], '%m/%Y')
      max_date = Date.strptime(params['build_year_max'], '%m/%Y') + 1.month - 1.day
      tenant_records = tenant_records.where(:build_date => min_date..max_date)
    elsif (!params['build_year_min'].blank?)
      min_date = Date.strptime(params['build_year_min'], '%m/%Y')
      tenant_records = tenant_records.where('build_date >= ?', min_date)
    elsif (!params['build_year_max'].blank?)
      max_date = Date.strptime(params['build_year_max'], '%m/%Y') + 1.month - 1.day
      tenant_records = tenant_records.where('build_date < ?', max_date)
    end

    if (!params['sold_year_min'].blank? && !params['sold_year_max'].blank?)
      min_date = Date.strptime(params['sold_year_min'], '%m/%Y')
      max_date = Date.strptime(params['sold_year_max'], '%m/%Y') + 1.month - 1.day
      tenant_records = tenant_records.where(:sold_date => min_date..max_date)
    elsif (!params['sold_year_min'].blank?)
      min_date = Date.strptime(params['sold_year_min'], '%m/%Y')
      tenant_records = tenant_records.where('sold_date >= ?', min_date)
    elsif (!params['sold_year_max'].blank?)
      max_date = Date.strptime(params['sold_year_max'], '%m/%Y') + 1.month - 1.day
      tenant_records = tenant_records.where('sold_date < ?', max_date)
    end

    if (!params['latitude'].blank? && !params['longitude'].blank?)
      params['latitude'] = params['latitude'].join(',')   if params['latitude'].is_a? Array
      params['longitude'] = params['longitude'].join(',') if params['longitude'].is_a? Array
      $min_latitude = params['latitude'].split(',').min
      $max_latitude = params['latitude'].split(',').max
      $min_longitude = params['longitude'].split(',').min
      $max_longitude = params['longitude'].split(',').max
      
      if (!params['connection'].blank? )
        ##tenant_records = tenant_records.ownership_lease.where("ownerships.account_id = ?" , params['connection'])
        tenant_records = tenant_records.where("user_id = ?" , params['connection'])
        connections_ids = params['connection']
        else
        @connections = Connection.all_connection_ids(current_user)
        ##p @con3
        tenant_records = tenant_records.where("user_id IN (?) OR user_id=?" , @connections.to_a,current_user.id)
        connections_ids = @connections.join(",")
        ##tenant_records = tenant_records.where("user_id = ?" , params['connection'])
      end
      
      tenant_records = tenant_records.where("(sale_records.latitude > ? AND sale_records.latitude < ? AND sale_records.longitude > ? AND sale_records.longitude < ?)", $min_latitude.to_f, $max_latitude.to_f, $max_longitude.to_f, $min_longitude.to_f)
    end

    #begin
    # Using SOLR instead
    #$found_id = []
    #$q = URI::encode("^"+params['q'])
    #uri = URI("http://67.23.43.218:8080/solr/collection1/select?q=address1%3A%22" + $q.to_s + "%22&rows=1000&df=address1&wt=json");
    #res = Net::HTTP.get_response(uri)
    #if (res.code == "200" && !res.body.blank?)
    #  json = JSON.parse res.body
    #  json['response']['docs'].each do |k|
    #    $found_id.push(k['id'].to_i)
    #  end
    #end
    #tenant_records = tenant_records.where("id IN (?)", $found_id)
    #rescue Exception => $e
    #  logger.debug "Unable to get solr request: " + $e.message
    #end
    # TODO look at code, fixe to use solr? NOT USING SOLR, JUST MYSQL
    unless params['latitude'].present? and params['longitude'].present?
      clause = if params['address1'].present? and params['zipcode'].present? and (params['search_type'] == 'address_zipcode')
                 { :where => "LOWER(sale_records.address1) = :address1 AND sale_records.zipcode = :zipcode",
                   :params => { :address1 => params['address1'].downcase, :zipcode => params['zipcode'].to_s }
                 }
               elsif params['q'].present?
                 if params['search_type'].present?
                   case params['search_type']
                     # when 'company'
                     #   {
                     #       :where => "LOWER(tenant_records.company) = :company",
                     #       :params => { :company => params['q'].downcase }
                     #   }
                     # when 'submarket'
                     #   {
                     #       :where => "LOWER(tenant_records.submarket) = :submarket",
                     #       :params => { :submarket => params['q'].downcase }
                     #   }
                     when 'property_name'
                       {
                           :where => "LOWER(sale_records.property_name) = :property_name",
                           :params => { :property_name => params['q'].downcase }
                       }
                      else
                        {
                           :where => "LOWER(sale_records.address1) LIKE :address1",
                           :params => { :address1 => "#{params['address1'].gsub(/[\.\s]/,'%')}%".downcase }
                        }
                   end
                 else
                   {
                       :where => "LOWER(sale_records.address1) LIKE :address1",
                       :params => { :address1 => "#{params['q'].gsub(/[\.\s]/,'%')}%".downcase }
                   }
                 end
               elsif params['term'].present?
                 {
                     :where => "LOWER(sale_records.address1) LIKE :address1",
                     :params => { :address1 => "#{params['term'].gsub(/[\.\s]/,'%')}%".downcase }
                 }
               end

      if (!params['connection'].blank? )
        ##tenant_records = tenant_records.ownership_lease.where("ownerships.account_id = ?" , params['connection'])
        tenant_records = tenant_records.where("user_id = ?" , params['connection'])
        connections_ids = params['connection']
        else
        @connections = Connection.all_connection_ids(current_user)
        ##p @con3
        tenant_records = tenant_records.where("user_id IN (?) OR user_id=?" , @connections.to_a,current_user.id)
        connections_ids = @connections.join(",")
        ##tenant_records = tenant_records.where("user_id = ?" , params['connection'])
      end
      
      
      
      query = "
select z.id,z.address1,z.user_id from (
select y.id,y.address1,y.user_id from sale_records y
            where (select count(*) from sale_records dt
            where  y.address1 = dt.address1
            and (dt.user_id in (#{connections_ids}) or dt.user_id = #{current_user.id})
            ) > 1 
and (y.user_id in (#{connections_ids}) or y.user_id=#{current_user.id}) order by y.address1 
) as z where z.user_id = #{current_user.id}
"

    dup_tenant_records = SaleRecord.find_by_sql(query)
    
    
      
      
      tenant_records = tenant_records
      .joins("left join (select * from activity_logs where comptype='sale' and initiator_id in (#{current_user.id})) as a on sale_records.id=a.comp_id")
      .joins("left join (select * from comp_requests where comp_type='sale' and initiator_id in (#{current_user.id})) as c on sale_records.id=c.comp_id")
      .order("address1,
        CASE 
          
          WHEN a.status is null AND c.comp_id is null THEN '1'
          
          WHEN c.comp_id > 0 THEN '2'
          
          WHEN a.status = 'full' THEN '3'
          WHEN a.status = 'partial' THEN '4'
          WHEN a.status = 'Rejected' THEN '5'
        
        ELSE a.status END ASC
         
      
        
        ")
      ##.joins("left join (select * from activity_logs where receiver_id!=#{current_user.id} and receiver_id not in (#{connections_ids}) ) as a on tenant_records.id=a.comp_id")
      ##.joins("left join (select * from comp_requests where receiver_id!=#{current_user.id} and receiver_id not in (#{connections_ids})) as c on tenant_records.id=c.comp_id")
      
        
        #hide child
        #####tenant_records = tenant_records.where("sale_records.id not in (select child_comp from activity_logs where comptype = 'sale' and ( receiver_id in (#{current_user.id})  ) and child_comp > 0)")
        #hide parent
        #####tenant_records = tenant_records.where("sale_records.id not in (select comp_id from activity_logs where comptype = 'sale' and ( initiator_id in (#{current_user.id})   )  and status = 'full_owner')")
        
        #####tenant_records = tenant_records.where("sale_records.id not in (select comp_id from activity_logs where comptype = 'sale' and ( initiator_id in (#{current_user.id})   )  and status = 'full_owner')")
        
        #####tenant_records = tenant_records.where("sale_records.id not in (select id from sale_records where user_id !=#{current_user.id} and master_id in (select master_id from activity_logs where comptype = 'sale' and ( initiator_id in (#{current_user.id})   )  and status = 'full_owner') ) ")
        
        ##select master_id from activity_logs where ( initiator_id in (#{current_user.id})  )  and status = 'full_owner' and master_id>0)
        
        ##tenant_records = tenant_records.where("( tenant_records.id in (select child_comp from activity_logs where ( initiator_id in (#{current_user.id})  )  and status = 'full_owner'))")
        
        ###tenant_records = tenant_records.where("tenant_records.id in (select comp_id from activity_logs where ( initiator_id in (#{current_user.id})  )  and status = 'full_owner')")
        
        
        tenant_records = tenant_records.where("sale_records.id not in (select id from sale_records as tr where user_id!=#{current_user.id} and tr.address1 in (?)) ",dup_tenant_records.join(","))
        
        
        
      ###tenant_records = tenant_records.where(clause[:where], clause[:params])
      tenant_records = tenant_records.where(clause[:where], clause[:params])
    end

    tenant_records
  end

end
