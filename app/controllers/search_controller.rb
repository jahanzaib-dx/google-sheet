class SearchController < ApplicationController
  include SearchControllerUtil
  include CushmanCalculationEngine
  include CalculatorUtil
  include CompHelper

  before_filter :authenticate_user!, except: [:comp_lookup, :comp_address_lookup]

  def offices
    res = Office.select('offices.id as office_id, firms.id as firm_id, firms.name as firm_name, offices.name as name').joins(:firm).where('offices.name like ? AND offices.firm_id = ? ', "#{params[:term]}%", params[:firm_id])
    respond_to do |format|
      format.json { render :json => { :term => $q, :results => res }}
    end
  end

  def sixsigma

    field = params[:field]
    field = 'free_rent_total' if params[:field] == 'free_rent'
    avg = params[:avg].to_f
    tile = params[:tile].to_f
    id = params[:id]

    rex = get_sixsigma(id, field, avg, tile) rescue nil

    respond_to do |format|
      format.json { render :json => { :params => params, :tile => tile, :selected_six_sigma => rex.selected_six_sigma }}
    end
  end

  def basic

    res = Array.new

    search_type = params[:search_type]
    term        = params[:term]
    address1    = params[:address1] if params.has_key? :address1
    zipcode     = params[:zipcode]  if params.has_key? :zipcode

    # SOLR query
    #$q = URI::encode("^" + term)
    #uri = URI("http://67.23.43.218:8080/solr/collection1/select?q=address1%3A%22" + $q.to_s + "*%22&rows=1000&df=address1&wt=json");
    #res = Net::HTTP.get(uri)
    ###if (current_user.has_trex_admin?)
	if (current_user)
      if (params[:sort].blank?)
        tenant_records = TenantRecord.address_only
      else
        tenant_records = TenantRecord.protect_view(current_user)
      end
    else # Check if firm_admin vs office_admin vs broker, vs analyst
      if (params[:sort].blank?)
        ######tenant_records = scope_address_only_office_user(params, current_user)
      else
        #####tenant_records = scope_protect_view_office_user(params, current_user)
      end
  end

    @connections = Connection.all_connection_ids(current_user)
    tenant_records = tenant_records.where("user_id IN (?) OR user_id=?" , @connections.to_a,current_user.id)

    clause = if address1.present? and zipcode.present?
               { :where => "LOWER(tenant_records.address1) = :address1 AND tenant_records.zipcode = :zipcode",
                 :params => { :address1 => address1.downcase, :zipcode => zipcode.to_s }
               }
             elsif term.present?
               term = term.strip.gsub(/[\.\s]/, '%') + '%'
               case search_type
                 when 'company'
                   { :where => "LOWER(tenant_records.company) LIKE :company",
                     :params => { :company => term.downcase }
                   }
                 when 'property_name'
                   { :where => "LOWER(tenant_records.property_name) LIKE :property_name",
                     :params => { :property_name => term.downcase }
                   }
                 when 'submarket'
                   { :where => "LOWER(tenant_records.submarket) LIKE :submarket",
                     :params => { :submarket => term.downcase }
                   }
                 else
                   { :where => "LOWER(tenant_records.address1) LIKE :address1",
                     :params => { :address1 => term.downcase }
                   }
               end
             end


    # MySQL query
    unless (clause.nil?)

      tenant_records = tenant_records.where(clause[:where], clause[:params])
      params['summary'] = false
      results = case search_type
                  when 'company'
                    tenant_records.order('company')
                  when 'property_name'
                    tenant_records.order('property_name')
                  when 'submarket'
                    tenant_records.order('submarket')
                  else
                    tenant_records.order('address1')
                end
      res = { :params => {:tenant_record => params }, :response => { :type => 'basic', :numFound => results.length, :docs => results } }
    end

    respond_to do |format|
      format.json { render :json => res }
    end
  end

  def advanced
    scope = scope_records_by_params(params[:tenant_record], current_user)
    #if this is the first page than calculate summary
    $order = 'address1'

    original_params = Marshal.load(Marshal.dump(params))

    # if summary, calculate quarters and find avg weighted market effective
    if params[:tenant_record][:summary]
      current = Date.today.beginning_of_quarter
      q1, q2, q3, q4 = (1..4).map { |i| Date.today.beginning_of_quarter.months_ago(i*3) }
      params['avg_weighted_tenant_effective'] = []
      # a = q1_avg.avg_cushman_market_effective.to_f
      #b = a
      q1_avg = scope.where(id: TenantRecord.scoped.lease_term_overlap(q1.end_of_quarter, current.end_of_quarter).select("id")).first
      params['avg_weighted_tenant_effective'] << (cushman_user ? q1_avg.avg_cushman_market_effective.to_f : q1_avg.avg_weighted_market_effective.to_f)

      q2_avg = scope.where(id: TenantRecord.scoped.lease_term_overlap(q2.end_of_quarter, q1.end_of_quarter).select("id")).first
      params['avg_weighted_tenant_effective'] << (cushman_user ? q2_avg.avg_cushman_market_effective.to_f : q2_avg.avg_weighted_market_effective.to_f)

      q3_avg = scope.where(id: TenantRecord.scoped.lease_term_overlap(q3.end_of_quarter, q2.end_of_quarter).select("id")).first
      params['avg_weighted_tenant_effective'] << (cushman_user ? q3_avg.avg_cushman_market_effective.to_f : q3_avg.avg_weighted_market_effective.to_f)

      q4_avg = scope.where(id: TenantRecord.scoped.lease_term_overlap(q4.end_of_quarter, q3.end_of_quarter).select("id")).first
      params['avg_weighted_tenant_effective'] << (cushman_user ? q4_avg.avg_cushman_market_effective.to_f : q4_avg.avg_weighted_market_effective.to_f)

      params['avg_weighted_tenant_effective_quarters'] = ["Current", get_quarter(q1), get_quarter(q2), get_quarter(q3)].reverse
      params['avg_weighted_tenant_effective'].reverse!

      if params[:tenant_record][:cost_display] == 'mo'
        params['avg_weighted_tenant_effective'].each_with_index do |single_avg, index|
          params['avg_weighted_tenant_effective'][index] = single_avg / 12.0
        end
      end

      #params['avg_weighted_tenant_effective'] = [53.0772056141280498,53.9177455557559932,54.4592933213889421,54.4012608930364223].reverse
    end

    if params.has_key? :radius and params[:tenant_record][:summary].blank?
      # no records found but we just need a record with a latitude/longitude pair, so we'll get rid of other parameters that
      # will prevent us from looking for an address
      scope = scope_records_by_params({"search_type" => params[:tenant_record][:search_type], "address1" => params[:tenant_record][:address1], "zipcode" => params[:tenant_record][:zipcode], "q" => params[:tenant_record][:q]}, current_user)
      t = scope.where('tenant_records.latitude is not null and tenant_records.longitude is not null').first

      latitude, longitude = apply_radius(params[:radius], t.latitude, t.longitude)
      params[:tenant_record][:latitude] = latitude
      params[:tenant_record][:longitude] = longitude
      params[:tenant_record].delete(:address1) if params[:tenant_record].has_key? :address1
      params[:tenant_record].delete(:zipcode) if params[:tenant_record].has_key? :zipcode
      params[:tenant_record].delete(:q)  if params[:tenant_record].has_key? :q
      tenant_records = scope_records_by_params params[:tenant_record], current_user
    end

    ####params['is_cushman_user'] = cushman_user
    # @NOTE specifying the table name, otherwise, the field returns sorted as a string, rather then integer
    $order = params[:tenant_record][:order] if (! params[:tenant_record][:order].blank?)


    tenant_records ||= scope


####@summary = tenant_records.all.first
    
    require 'will_paginate/array'
    
    tenant_records = lockTenantRecord tenant_records
    
    respond_to do |format|
      if (params[:tenant_record][:summary].blank?)
        session[:search_params] = original_params unless params.has_key? :previous # only if store if it's not a previous requery
        #format.json { render json: { type: 'advanced', res: @tenant_records.limit(100).offset(params['tenant_record'][:offset]).order($order), count: @tenant_records.length, params:params } }
		
		    format.html  # index.html.erb
		
        ####format.json { render json: { type: 'advanced', res: tenant_records.paginate(:page => params['tenant_record'][:page].to_i, :per_page => 100).order($order), count: tenant_records.length, params:params } }
        format.json { render json: { type: 'advanced', res: tenant_records.paginate(:page => params['tenant_record'][:page].to_i, :per_page => 100), count: tenant_records.length, params:params } }
      else
        ###format.json { render json: { type: 'advanced', summary: tenant_records.all.first, count: tenant_records.all.first.total_count, params:params } }
		
		
		format.html { render html }
		
		
      end
    end

  end
  
  def lockTenantRecord tenant_records
    
       tenant_records = tenant_records.each do |t_record|
          
          if t_record.user_id != current_user.id
            
             ##compObj = OpenStruct.new() ## convert hash(asso array) to object
             
             ##compArr = Hash.new
             unlockFields = []
             
              ##t_record.address1 = "Locked"
              ##where("comp_id = ? AND agent_id = ? AND comp_type = ? ", activity.comp_id,activity.receiver_id,activity.comptype ).
              activity = ActivityLog.where(:comp_id => t_record.id, :initiator_id => current_user.id, :comptype => "lease").first
              ##activity = OpenStruct.new({:comp_id => t_record.id, :initiator_id => current_user.id, :comptype => "lease"}) ## convert hash(asso array) to object
              if activity.present?
                
                ##compArr['cp_status'] = activity.status
                ##compObj.cp_status = activity.status
                
                t_record.cp_status = activity.status
                
                if activity.status == CompRequest::FULL
                  next 
                end             
                
                if activity.status == CompRequest::PARTIAL
                  unlockFields = SharedComp.getUnlockData activity
                end
              
              else
                comp_request = CompRequest.where(:comp_id => t_record.id, :initiator_id => current_user.id, :comp_type => "lease").first
                
                if comp_request.present?
                  t_record.cp_status = "Waiting"
                end
                
              end
    
              t_record.company = if unlockFields.include?"company" then t_record.company else 'Lock' end
              t_record.base_rent = if unlockFields.include?"base_rent" then t_record.base_rent else 'Lock' end
              t_record.size_range = if unlockFields.include?"size" then t_record.size else sf_range(t_record.size) end
              t_record.size = if unlockFields.include?"size" then t_record.size else "0" end
              
                
              ##t_record = t_record + compArr
              ##t_record = t_record + compObj
              p t_record.cp_status
              ##t_record.merge(compObj)
             
                       
          end
       
       end
   
   end
   
   def lockSaleRecord tenant_records
    
       tenant_records = tenant_records.each do |t_record|
         
         t_record.price_str = t_record.price
         t_record.cap_rate_str = t_record.cap_rate
         t_record.land_size_str = t_record.land_size
          
          if t_record.user_id != current_user.id
            
             ##compObj = OpenStruct.new() ## convert hash(asso array) to object
              
              ##t_record.date_sold = 
             
             ##compArr = Hash.new
             unlockFields = []
             
              ##t_record.address1 = "Locked"
              ##where("comp_id = ? AND agent_id = ? AND comp_type = ? ", activity.comp_id,activity.receiver_id,activity.comptype ).
              activity = ActivityLog.where(:comp_id => t_record.id, :initiator_id => current_user.id, :comptype => "sale").first
              ##activity = OpenStruct.new({:comp_id => t_record.id, :initiator_id => current_user.id, :comptype => "lease"}) ## convert hash(asso array) to object
              if activity.present?
                
                ##compArr['cp_status'] = activity.status
                ##compObj.cp_status = activity.status
                
                t_record.cp_status = activity.status
                
                if activity.status == CompRequest::FULL
                  next 
                end             
                
                if activity.status == CompRequest::PARTIAL
                  unlockFields = SharedComp.getUnlockData activity
                end
              
              else
                comp_request = CompRequest.where(:comp_id => t_record.id, :initiator_id => current_user.id, :comp_type => "sale").first
                
                if comp_request.present?
                  t_record.cp_status = "Waiting"
                end
                
              end
    
              t_record.price_str = if unlockFields.include?"price" then t_record.price else 'Lock' end
              t_record.cap_rate_str = if unlockFields.include?"cap_rate" then t_record.base_rent else 'Lock' end
              t_record.land_size_str = if unlockFields.include?"land_size" then t_record.land_size else sf_range(t_record.land_size,'sale') end
                
              ##t_record = t_record + compArr
              ##t_record = t_record + compObj
              p t_record.cp_status
              ##t_record.merge(compObj)
             
                       
          end
       
       end
   
   end
   
   def lockSingleSaleRecord t_record
     
              t_record.price_str =  number_to_currency(t_record.price.to_f, {:precision=>2})
              t_record.size_range = t_record.land_size
              t_record.build_date_str = (t_record.build_date.blank? == true)?"":t_record.build_date.year
              t_record.cap_rate_str = "#{t_record.cap_rate}%"


          if t_record.user_id != current_user.id
            
             unlockFields = []
             
              activity = ActivityLog.where(:comp_id => t_record.id, :initiator_id => current_user.id, :comptype => "lease").first

              if activity.present?
                
                ##compArr['cp_status'] = activity.status
                ##compObj.cp_status = activity.status
                
                t_record.cp_status = activity.status
                
                if activity.status == CompRequest::FULL
                  ##next
                  return t_record
                end             
                
                if activity.status == CompRequest::PARTIAL
                  unlockFields = SharedComp.getUnlockData activity
                end
              
              else
                comp_request = CompRequest.where(:comp_id => t_record.id, :initiator_id => current_user.id, :comp_type => "lease").first
                
                if comp_request.present?
                  t_record.cp_status = "Waiting"
                end
                
              end
              
              t_record.price_str =  number_to_currency(t_record.price.to_f, {:precision=>2})
              ##t_record.size_range = t_record.land_size
              ##t_record.build_date_str = (t_record.build_date.blank? == true)?"":t_record.build_date.year
              
              t_record.price_str = if unlockFields.include?"price" then t_record.price else 'Lock' end
              t_record.size_range = if unlockFields.include?"land_size" then t_record.land_size else sf_range(t_record.land_size,'sale') end
              
              t_record.property_type = if unlockFields.include?"property_type" then t_record.property_type else 'Lock' end
              t_record.class_type = if unlockFields.include?"class_type" then t_record.class_type else 'Lock' end
              t_record.build_date_str = if unlockFields.include?"build_date" then (t_record.build_date.blank? == true)?"":t_record.build_date.year else 'Lock' end
                   
              ##t_record.suite = if unlockFields.include?"suite" then t_record.company else 'Lock' end
              t_record.city = if unlockFields.include?"city" then t_record.city else 'Lock' end
              t_record.state = if unlockFields.include?"state" then t_record.state else 'Lock' end
              t_record.zipcode = if unlockFields.include?"zipcode" then t_record.zipcode else 'Lock' end
                
              t_record.submarket = if unlockFields.include?"submarket" then t_record.submarket else 'Lock' end
              t_record.cap_rate_str = if unlockFields.include?"cap_rate" then "#{t_record.cap_rate}%" else 'Lock' end
                
                       
          end
          
          t_record
       
   
   end
   
   def lockSingleTenantRecord t_record
     
              t_record.base_rent_str = number_to_currency(t_record.base_rent.to_f,{:precision=>2})
              t_record.size_range = t_record.size


              t_record.escalation_str = t_record.escalation
              t_record.lease_commencement_date_str = t_record.lease_commencement_date.strftime('%m/%d/%Y')
              t_record.lease_term_months_str = t_record.lease_term_months

              t_record.tenant_improvement_str = number_to_currency(t_record.tenant_improvement.to_f,{:precision=>2})
              t_record.landlord_concessions_per_sf_str = number_to_currency(t_record.landlord_concessions_per_sf.to_f,{:precision=>2})
              t_record.tenant_ti_cost_str = number_to_currency(t_record.tenant_ti_cost.to_f,{:precision=>2})


          if t_record.user_id != current_user.id
            
             unlockFields = []
             
              activity = ActivityLog.where(:comp_id => t_record.id, :initiator_id => current_user.id, :comptype => "lease").first

              if activity.present?
                
                ##compArr['cp_status'] = activity.status
                ##compObj.cp_status = activity.status
                
                t_record.cp_status = activity.status
                
                if activity.status == CompRequest::FULL
                  ##next
                  return t_record
                end             
                
                if activity.status == CompRequest::PARTIAL
                  unlockFields = SharedComp.getUnlockData activity
                end
              
              else
                comp_request = CompRequest.where(:comp_id => t_record.id, :initiator_id => current_user.id, :comp_type => "lease").first
                
                if comp_request.present?
                  t_record.cp_status = "Waiting"
                end
                
              end
    
              t_record.company = if unlockFields.include?"company" then t_record.company else 'Lock' end
              t_record.base_rent_str = if unlockFields.include?"base_rent" then number_to_currency(t_record.base_rent.to_f,{:precision=>2}) else 'Lock' end
              t_record.size_range = if unlockFields.include?"size" then t_record.size else sf_range(t_record.size) end
              t_record.size = if unlockFields.include?"size" then t_record.size else "0" end
              
              t_record.suite = if unlockFields.include?"suite" then t_record.company else 'Lock' end
              t_record.city = if unlockFields.include?"city" then t_record.city else 'Lock' end
              t_record.state = if unlockFields.include?"state" then t_record.state else 'Lock' end
              t_record.zipcode = if unlockFields.include?"zipcode" then t_record.zipcode else 'Lock' end
                
              t_record.property_name = if unlockFields.include?"property_name" then t_record.property_name else 'Lock' end
              t_record.industry_type = if unlockFields.include?"industry_type" then t_record.industry_type else 'Lock' end
              t_record.property_type = if unlockFields.include?"property_type" then t_record.property_type else 'Lock' end
              t_record.class_type = if unlockFields.include?"class_type" then t_record.class_type else 'Lock' end
                
              t_record.escalation_str = if unlockFields.include?"escalation" then t_record.escalation else 'Lock' end
              ##t_record.lease_commencement_date_str = if unlockFields.include?"lease_commencement_date" then t_record.lease_commencement_date.strftime('%m/%d/%Y') else 'Lock' end
              t_record.lease_term_months_str = if unlockFields.include?"lease_term_months" then t_record.lease_term_months else 'Lock' end
              t_record.free_rent = if unlockFields.include?"free_rent" then t_record.free_rent else 'Lock' end
                
              t_record.tenant_improvement_str = if unlockFields.include?"tenant_improvement" then number_to_currency(t_record.tenant_improvement.to_f,{:precision=>2}) else 'Lock' end
              t_record.landlord_concessions_per_sf_str = if unlockFields.include?"landlord_concessions_per_sf" then number_to_currency(t_record.landlord_concessions_per_sf.to_f,{:precision=>2}) else 'Lock' end
              t_record.tenant_ti_cost_str = if unlockFields.include?"tenant_ti_cost" then number_to_currency(t_record.tenant_ti_cost.to_f,{:precision=>2}) else 'Lock' end
              t_record.submarket = if unlockFields.include?"submarket" then t_record.size else 'Lock' end
                
              t_record.lease_type = if unlockFields.include?"lease_type" then t_record.lease_type else 'Lock' end
              ## not working t_record.data['leasestructure_name'] = if unlockFields.include?"leasestructure_name" then t_record.data['leasestructure_name'] else 'Lock' end
              
                       
          end
          
          t_record
       
   
   end

  def industry

    #sic_codes = IndustrySicCode.where('value ILIKE ? OR description ILIKE ?', "%#{params[:search]}%", "%#{params[:search]}%").limit(20)
    industry_types = TenantRecord.where('industry_type ILIKE ? ', "%#{params[:search]}%").pluck(:industry_type).uniq
    render js: "#{params[:callback]}(#{industry_types.to_json});"

  end

  def teams
    teams = Team.where('office_id = ? AND name ILIKE ?', current_user.account.office_id, "%#{params[:search]}%").limit(20)

    render js: "#{params[:callback]}(#{teams.to_json});"

  end

  def lease_types
    ret = TenantRecord.select('lease_type').group('lease_type').order('lease_type').map{ |w| { label: w.lease_type, value: w.lease_type } }
    render js: "#{params[:callback]}(#{ret.to_json});"
  end

  def export
    e = TenantRecordExporter

    if params[:filename]
      # check for exported file
      f = params[:filename]
      render :layout => false, :status => :not_found and return unless e.exists?(f)

      done = e.done?(f)
      if request.post?
        render :layout => false, :status => (done) ? :ok : :accepted
      else
        send_file e.path(f), :type => e.mime_type(f) if done
      end
    else
      filename = e.export_file params, current_user.id, params[:export_type].to_sym, request, cushman_user, params[:template_id]
      render :json => { filename: filename  }
    end
  end

  def analytics
    #params = Rack::Utils.parse_nested_query("ma_net_effective=true&ma_landlord_concession=true&ma_landlord_effective_rent=true&industry_comparison=&asset_comparison=true&include_criteria=true&pdf_type=analytics&tenant_record%5Bsimple_search_latitude%5D=41.070470502&tenant_record%5Bsimple_search_longitude%5D=-73.769302886&tenant_record%5Border%5D=&tenant_record%5Boffset%5D=&tenant_record%5Blatitude%5D=41.070470502%2C41.08845586967594%2C41.070468042042044%2C41.05248513432406%2C41.070468042042044&tenant_record%5Blongitude%5D=-73.769302886%2C-73.76930288600002%2C-73.74544651612057%2C-73.76930288600002%2C-73.79315925587937&tenant_record%5Blease_commencement_date_min%5D=&tenant_record%5Blease_commencement_date_max%5D=&tenant_record%5Bsize_min%5D=&tenant_record%5Bsize_max%5D=&tenant_record%5Bindustry_sic_code%5D=5&tenant_record%5Bapply_radius%5D=true&tenant_record%5Bradius%5D=2&q=902+Broadway&export_type=pdf")

    scoped_records = scope_records_by_params(params['tenant_record'].merge!({'q'=> params['q'], 'summary' => false, 'analytics_view'=>true}), current_user)
    @is_cushman_user = cushman_user
    # asset comparison
    if params['asset_comparison'].present?
      if is_cushman_user
        @asset_comparison = scoped_records
        .select("COALESCE(SUM((tenant_records.cushman_net_effective_per_sf * tenant_records.size)::decimal)/SUM(tenant_records.size)::decimal, 0) AS average_net_effective_per_sf " +
                    ", COALESCE(SUM((tenant_records.data->'landlord_effective_per_annum')::decimal)/SUM(tenant_records.size)::decimal,0) AS avg_landlord_effective_per_annum " +
                    ",tenant_records.address1")
        .group('tenant_records.address1')
        .order('average_net_effective_per_sf desc')
        .all
      else
        @asset_comparison = scoped_records
        .select("COALESCE(SUM((tenant_records.data->'tenant_effective_per_annum')::decimal)/SUM(tenant_records.size)::decimal, 0) AS average_net_effective_per_sf " +
                    ", COALESCE(SUM((tenant_records.data->'landlord_effective_per_annum')::decimal)/SUM(tenant_records.size)::decimal,0) AS avg_landlord_effective_per_annum " +
                    ",tenant_records.address1")
        .group('tenant_records.address1')
        .order('average_net_effective_per_sf desc')
        .all
      end
    end
    @bars_per_page = 6

    if params['ma_net_effective'].present?
      if is_cushman_user
        @market_net_effective = scoped_records
        .except(:group)
        .group('EXTRACT(year FROM lease_commencement_date)')
        .average(:cushman_net_effective_per_sf)
      else
        @market_net_effective = scoped_records
        .except(:group)
        .group('EXTRACT(year FROM lease_commencement_date)')
        .average(:net_effective_per_sf)
      end
    end

    if params['ma_landlord_concession'].present?
      @market_landlord_concessions = scoped_records
      .except(:group)
      .group('EXTRACT(year FROM lease_commencement_date)')
      .average(:landlord_concessions_per_sf)
    end

    if params['industry_comparison'].present?
      if is_cushman_user
        @industry_comparison = scoped_records
        .select('EXTRACT( year FROM lease_commencement_date) as year, EXTRACT(month FROM lease_commencement_date) as month, cushman_net_effective_per_sf')
        .all
      else
        @industry_comparison = scoped_records
        .select('EXTRACT( year FROM lease_commencement_date) as year, EXTRACT(month FROM lease_commencement_date) as month, net_effective_per_sf')
        .all
      end
    end

    @params = params['tenant_record'].merge('include_criteria' => 'true') if params['include_criteria'].present?

    @all = scoped_records
    @user = current_user

    render :layout => 'report'
  end

  # create dashboard query and display results for Wirewax using comp_id
  def comp_lookup
    if params[:comp_id]
      begin
        @tenant_record = TenantRecord.find(params[:comp_id])
        result = get_dashboard_query_url(:previous => true, :address1 => @tenant_record.address1, :zipcode => @tenant_record.zipcode,
                                         :search_type => "address_zipcode")

        redirect_to dashboard_path(result)
      rescue => exception
        @exception = exception.message
      end
    end
  end

  # create dashboard query and display results using address and zipcode
  def comp_address_lookup
    params_exist = false
    if params[:address] and params[:zipcode]
      begin
        result = get_dashboard_query_url(:previous => true, :address1 => params[:address], :zipcode => params[:zipcode],
                                         :search_type => "address_zipcode")
        params_exist = true
        redirect_to dashboard_path(result)
      rescue => exception
        @exception = exception.message
      end
    end
    render 'comp_lookup' unless params_exist
  end

  ## Development only
  def report
    @user = current_user
    template_id = params[:custom_report_template_id]
    is_cushman_user = false

    params = Rack::Utils.parse_nested_query("ma_net_effective=true&ma_landlord_concession=true&ma_landlord_effective_rent=true&industry_comparison=&asset_comparison=true&include_criteria=true&pdf_type=analytics&tenant_record%5Bsimple_search_latitude%5D=41.070470502&tenant_record%5Bsimple_search_address%5D=902+Broadway&tenant_record%5Bsimple_search_longitude%5D=-73.769302886&tenant_record%5Border%5D=&tenant_record%5Boffset%5D=&tenant_record%5Blatitude%5D=41.070470502%2C41.08845586967594%2C41.070468042042044%2C41.05248513432406%2C41.070468042042044&tenant_record%5Blongitude%5D=-73.769302886%2C-73.76930288600002%2C-73.74544651612057%2C-73.76930288600002%2C-73.79315925587937&tenant_record%5Blease_commencement_date_min%5D=&tenant_record%5Blease_commencement_date_max%5D=&tenant_record%5Bsize_min%5D=&tenant_record%5Bsize_max%5D=&tenant_record%5Bindustry_sic_code%5D=&tenant_record%5Bapply_radius%5D=true&tenant_record%5Bradius%5D=2&q=315+Park+Ave+S &export_type=pdf")
    @summary = scope_records_by_params(params['tenant_record'].merge!({'q'=> params['q'], 'summary' => true}), current_user).all.first

    tenant_record = TenantRecord.protect_view(@user).scoped.find(628)
    @financial_detail = calculate(tenant_record, 'TenantEffective')[:summary]

    @custom_template = CustomReport.get_template_by_id(template_id)
    sixsigma_results = tenant_record.protected? ? sixsigma(tenant_record) : nil
    @record = tenant_record
    assigned_vars = {:user => @user, :sixsigma => sixsigma_results, :record => tenant_record, :summary => @summary, :is_cushman_user => is_cushman_user, :custom_template => @custom_template, :financial_detail => @financial_detail}
    render :template => 'search/custom_report/single/custom_single_report', :layout => 'layouts/report'
  end




#basic search for sales
  def address

    record_type     = params[:record_type]
    if record_type == 'lease'
      basic
    elsif record_type == 'sale'
      simple
    end

  end

  #basic search for sales
  def simple

    res = Array.new

    search_type = params[:search_type]
    term        = params[:term]
    address1    = params[:address1] if params.has_key? :address1
    zipcode     = params[:zipcode]  if params.has_key? :zipcode

    # SOLR query
    #$q = URI::encode("^" + term)
    #uri = URI("http://67.23.43.218:8080/solr/collection1/select?q=address1%3A%22" + $q.to_s + "*%22&rows=1000&df=address1&wt=json");
    #res = Net::HTTP.get(uri)
    ###if (current_user.has_trex_admin?)
    if (current_user)
      if (params[:sort].blank?)
        tenant_records = SaleRecord.address_only
      else
        #tenant_records = TenantRecord.protect_view(current_user)
      end
    else # Check if firm_admin vs office_admin vs broker, vs analyst
      if (params[:sort].blank?)
        ######tenant_records = scope_address_only_office_user(params, current_user)
      else
        #####tenant_records = scope_protect_view_office_user(params, current_user)
      end
    end

    clause = if address1.present? and zipcode.present?
               { :where => "LOWER(sale_records.address1) = :address1 AND sale_records.zipcode = :zipcode",
                 :params => { :address1 => address1.downcase, :zipcode => zipcode.to_s }
               }
             elsif term.present?
               term = term.strip.gsub(/[\.\s]/, '%') + '%'
               case search_type
                 when 'company'
                   { :where => "LOWER(tenant_records.company) LIKE :company",
                     :params => { :company => term.downcase }
                   }
                 when 'property_name'
                   { :where => "LOWER(tenant_records.property_name) LIKE :property_name",
                     :params => { :property_name => term.downcase }
                   }
                 when 'submarket'
                   { :where => "LOWER(tenant_records.submarket) LIKE :submarket",
                     :params => { :submarket => term.downcase }
                   }
                 else
                   { :where => "LOWER(sale_records.address1) LIKE :address1",
                     :params => { :address1 => term.downcase }
                   }
               end
             end


    # MySQL query
    unless (clause.nil?)

      @connections = Connection.all_connection_ids(current_user)
      tenant_records = tenant_records.where("user_id IN (?) OR user_id=?" , @connections.to_a,current_user.id)

      tenant_records = tenant_records.where(clause[:where], clause[:params])
      params['summary'] = false
      results = case search_type
                  when 'company'
                    tenant_records.order('company')
                  when 'property_name'
                    tenant_records.order('property_name')
                  when 'submarket'
                    tenant_records.order('submarket')
                  else
                    tenant_records.order('address1')
                end
      res = { :params => {:tenant_record => params }, :response => { :type => 'basic', :numFound => results.length, :docs => results } }
    end

    respond_to do |format|
      format.json { render :json => res }
    end

    end



#advance search for sales
  def sales

    scope = sales_scope_records_by_params(params[:tenant_record], current_user)
    #if this is the first page than calculate summary
    $order = 'address1'

    original_params = Marshal.load(Marshal.dump(params))

    # if summary, calculate quarters and find avg weighted market effective
    if params[:tenant_record][:summary]
      current = Date.today.beginning_of_quarter
      q1, q2, q3, q4 = (1..4).map { |i| Date.today.beginning_of_quarter.months_ago(i*3) }
      params['avg_weighted_tenant_effective'] = []
      # a = q1_avg.avg_cushman_market_effective.to_f
      #b = a
      q1_avg = scope.where(id: TenantRecord.scoped.lease_term_overlap(q1.end_of_quarter, current.end_of_quarter).select("id")).first
      params['avg_weighted_tenant_effective'] << (cushman_user ? q1_avg.avg_cushman_market_effective.to_f : q1_avg.avg_weighted_market_effective.to_f)

      q2_avg = scope.where(id: TenantRecord.scoped.lease_term_overlap(q2.end_of_quarter, q1.end_of_quarter).select("id")).first
      params['avg_weighted_tenant_effective'] << (cushman_user ? q2_avg.avg_cushman_market_effective.to_f : q2_avg.avg_weighted_market_effective.to_f)

      q3_avg = scope.where(id: TenantRecord.scoped.lease_term_overlap(q3.end_of_quarter, q2.end_of_quarter).select("id")).first
      params['avg_weighted_tenant_effective'] << (cushman_user ? q3_avg.avg_cushman_market_effective.to_f : q3_avg.avg_weighted_market_effective.to_f)

      q4_avg = scope.where(id: TenantRecord.scoped.lease_term_overlap(q4.end_of_quarter, q3.end_of_quarter).select("id")).first
      params['avg_weighted_tenant_effective'] << (cushman_user ? q4_avg.avg_cushman_market_effective.to_f : q4_avg.avg_weighted_market_effective.to_f)

      params['avg_weighted_tenant_effective_quarters'] = ["Current", get_quarter(q1), get_quarter(q2), get_quarter(q3)].reverse
      params['avg_weighted_tenant_effective'].reverse!

      if params[:tenant_record][:cost_display] == 'mo'
        params['avg_weighted_tenant_effective'].each_with_index do |single_avg, index|
          params['avg_weighted_tenant_effective'][index] = single_avg / 12.0
        end
      end

      #params['avg_weighted_tenant_effective'] = [53.0772056141280498,53.9177455557559932,54.4592933213889421,54.4012608930364223].reverse
    end

    if params.has_key? :radius and params[:tenant_record][:summary].blank?
      # no records found but we just need a record with a latitude/longitude pair, so we'll get rid of other parameters that
      # will prevent us from looking for an address
      scope = scope_records_by_params({"search_type" => params[:tenant_record][:search_type], "address1" => params[:tenant_record][:address1], "zipcode" => params[:tenant_record][:zipcode], "q" => params[:tenant_record][:q]}, current_user)
      t = scope.where('tenant_records.latitude is not null and tenant_records.longitude is not null').first

      latitude, longitude = apply_radius(params[:radius], t.latitude, t.longitude)
      params[:tenant_record][:latitude] = latitude
      params[:tenant_record][:longitude] = longitude
      params[:tenant_record].delete(:address1) if params[:tenant_record].has_key? :address1
      params[:tenant_record].delete(:zipcode) if params[:tenant_record].has_key? :zipcode
      params[:tenant_record].delete(:q)  if params[:tenant_record].has_key? :q
      tenant_records = scope_records_by_params params[:tenant_record], current_user
    end

    ####params['is_cushman_user'] = cushman_user
    # @NOTE specifying the table name, otherwise, the field returns sorted as a string, rather then integer
    $order = params[:tenant_record][:order] if (! params[:tenant_record][:order].blank?)


    tenant_records ||= scope


    ##@summary = tenant_records.all.first
    
    require 'will_paginate/array'
    
    tenant_records = lockSaleRecord tenant_records

    
    respond_to do |format|
      if (params[:tenant_record][:summary].blank?)
        session[:search_params] = original_params unless params.has_key? :previous # only if store if it's not a previous requery
        #format.json { render json: { type: 'advanced', res: @tenant_records.limit(100).offset(params['tenant_record'][:offset]).order($order), count: @tenant_records.length, params:params } }

        format.html  # index.html.erb

        ##format.json { render json: { type: 'advanced', res: tenant_records.paginate(:page => params['tenant_record'][:page].to_i, :per_page => 100).order($order), count: tenant_records.length, params:params } }
        format.json { render json: { type: 'advanced', res: tenant_records.paginate(:page => params['tenant_record'][:page].to_i, :per_page => 100), count: tenant_records.length, params:params } }
      else
        format.json { render json: { type: 'advanced', summary: tenant_records.all.first, count: tenant_records.all.first.total_count, params:params } }


        format.html { render html }


      end
    end
  end

  # ---------------------

  def comp
    if (!params[:id].blank?)
        comp_id = params[:id]
        @comp_record = TenantRecord.find(comp_id)
    end

    #render "comp"

    render(
        partial: 'comp', :locals =>{:comp_record => @comp_record}
        #partial: 'comp'
    #,
     #   locals: { heading: heading, block: block }
    )
    #render json: {:data => params[:id] }

    ##render comp

    # respond_to do |format|
    #
    #
    #     #format.json { render json: { type: 'advanced', params:params } }
    #
    #
    #     format.html { render html }
    #
    #
    #   end

  end

  def lease_comp
    if (!params[:id].blank?)
      comp_id = params[:id]
      
      ##@comp_record = TenantRecord.select_extra().where(:id=>comp_id)
      comp = TenantRecord.select("*").select_extra().find(comp_id)
      #p comp
      
      @comp_record = lockSingleTenantRecord comp
      #p @comp_record
      
    end
    render "lease_comp"
  end

  def sale_comp
    if (!params[:id].blank?)
      comp_id = params[:id]      
      ##@comp_record = SaleRecord.find(comp_id)
      
      comp = SaleRecord.select("*").select_extra().find(comp_id)
      
      @comp_record = lockSingleSaleRecord comp
    end
    render "sale_comp"
  end

  def lease_comp_pdf
    if (!params[:id].blank?)
      comp_id = params[:id]
      #@comp_record = TenantRecord.find(comp_id)
      comp = TenantRecord.select("*").select_extra().find(comp_id)
      @comp_record = lockSingleTenantRecord comp
    end
    render :pdf => "lease_comp_pdf" ##any name
  end

  def sale_comp_pdf
    if (!params[:id].blank?)
      comp_id = params[:id]
      ##@comp_record = SaleRecord.find(comp_id)
      
      comp = SaleRecord.select("*").select_extra().find(comp_id)
      
      @comp_record = lockSingleSaleRecord comp
    end
    render :pdf => "sale_comp_pdf"
  end

  def database_lease
    require "google_drive"
    require 'digest/sha1'
    require 'time'
    scope = scope_records_by_params(params[:tenant_record], current_user)
    #if this is the first page than calculate summary
    $order = 'address1'

    original_params = Marshal.load(Marshal.dump(params))

    # if summary, calculate quarters and find avg weighted market effective
    if params[:tenant_record][:summary]
      current = Date.today.beginning_of_quarter
      q1, q2, q3, q4 = (1..4).map { |i| Date.today.beginning_of_quarter.months_ago(i*3) }
      params['avg_weighted_tenant_effective'] = []
      # a = q1_avg.avg_cushman_market_effective.to_f
      #b = a
      q1_avg = scope.where(id: TenantRecord.scoped.lease_term_overlap(q1.end_of_quarter, current.end_of_quarter).select("id")).first
      params['avg_weighted_tenant_effective'] << (cushman_user ? q1_avg.avg_cushman_market_effective.to_f : q1_avg.avg_weighted_market_effective.to_f)

      q2_avg = scope.where(id: TenantRecord.scoped.lease_term_overlap(q2.end_of_quarter, q1.end_of_quarter).select("id")).first
      params['avg_weighted_tenant_effective'] << (cushman_user ? q2_avg.avg_cushman_market_effective.to_f : q2_avg.avg_weighted_market_effective.to_f)

      q3_avg = scope.where(id: TenantRecord.scoped.lease_term_overlap(q3.end_of_quarter, q2.end_of_quarter).select("id")).first
      params['avg_weighted_tenant_effective'] << (cushman_user ? q3_avg.avg_cushman_market_effective.to_f : q3_avg.avg_weighted_market_effective.to_f)

      q4_avg = scope.where(id: TenantRecord.scoped.lease_term_overlap(q4.end_of_quarter, q3.end_of_quarter).select("id")).first
      params['avg_weighted_tenant_effective'] << (cushman_user ? q4_avg.avg_cushman_market_effective.to_f : q4_avg.avg_weighted_market_effective.to_f)

      params['avg_weighted_tenant_effective_quarters'] = ["Current", get_quarter(q1), get_quarter(q2), get_quarter(q3)].reverse
      params['avg_weighted_tenant_effective'].reverse!

      if params[:tenant_record][:cost_display] == 'mo'
        params['avg_weighted_tenant_effective'].each_with_index do |single_avg, index|
          params['avg_weighted_tenant_effective'][index] = single_avg / 12.0
        end
      end

      #params['avg_weighted_tenant_effective'] = [53.0772056141280498,53.9177455557559932,54.4592933213889421,54.4012608930364223].reverse
    end

    if params.has_key? :radius and params[:tenant_record][:summary].blank?
      # no records found but we just need a record with a latitude/longitude pair, so we'll get rid of other parameters that
      # will prevent us from looking for an address
      scope = scope_records_by_params({"search_type" => params[:tenant_record][:search_type], "address1" => params[:tenant_record][:address1], "zipcode" => params[:tenant_record][:zipcode], "q" => params[:tenant_record][:q]}, current_user)
      t = scope.where('tenant_records.latitude is not null and tenant_records.longitude is not null').first

      latitude, longitude = apply_radius(params[:radius], t.latitude, t.longitude)
      params[:tenant_record][:latitude] = latitude
      params[:tenant_record][:longitude] = longitude
      params[:tenant_record].delete(:address1) if params[:tenant_record].has_key? :address1
      params[:tenant_record].delete(:zipcode) if params[:tenant_record].has_key? :zipcode
      params[:tenant_record].delete(:q)  if params[:tenant_record].has_key? :q
      tenant_records = scope_records_by_params params[:tenant_record], current_user
    end

    ####params['is_cushman_user'] = cushman_user
    # @NOTE specifying the table name, otherwise, the field returns sorted as a string, rather then integer
    $order = params[:tenant_record][:order] if (! params[:tenant_record][:order].blank?)


    tenant_records ||= scope


    @summary = tenant_records.all.first










    if TenantRecord.max_stepped_rent_by_user(current_user.id).first!=nil
      stepped_rent_count = TenantRecord.max_stepped_rent_by_user(current_user.id).first.countof
    else
      stepped_rent_count=0
    end
    time = Time.now.getutc
    fileName = Digest::SHA1.hexdigest("#{time}#{@current_user}")
    session = GoogleDrive::Session.from_config("#{Rails.root}/config/google-sheets.json")

      @file = session.drive.copy_file('1simT-7peFhoY-k9zrov3XYP4XpWJKPQRMz2sQYA5F1Y', {name: "#{@current_user.id}_temp"}, {})

      # put data to sheet
      ws = session.spreadsheet_by_key(@file.id).worksheets[0]
      counter=2
      i=1
      stepped_rent_col_head=21
      while i <= stepped_rent_count  do
        ws[1,stepped_rent_col_head] = "Step #{i} Cost Per SF"
        ws[1,stepped_rent_col_head+1] = "# of Months"
        i +=1
        stepped_rent_col_head+=2
      end
      tenant_records.each do |tenant_record|
        stepped_rent_col=21
        ws[counter, 1] = tenant_record.id
        ws[counter, 2] = (tenant_record.main_image_file_name.present?) ? tenant_record.main_image_file_name : '=image("https://maps.googleapis.com/maps/api/streetview?size=350x200&location='+"#{tenant_record.latitude},#{tenant_record.longitude}"+'&heading=151.78&pitch=-0.76",2)'
        ws[counter, 3] = tenant_record.comp_type
        ws[counter, 4] = tenant_record.company
        ws[counter, 5] = tenant_record.industry_type
        ws[counter, 6] = tenant_record.address1
        ws[counter, 7] = tenant_record.suite
        ws[counter, 8] = tenant_record.city
        ws[counter, 9] = tenant_record.state
        ws[counter, 10] = tenant_record.submarket
        ws[counter, 11] = tenant_record.class_type
        ws[counter, 12] = tenant_record.property_type
        ws[counter, 13] = tenant_record.property_name
        ws[counter, 14] = tenant_record.lease_commencement_date
        ws[counter, 15] = tenant_record.lease_term_months
        ws[counter, 16] = tenant_record.free_rent
        ws[counter, 17] = tenant_record.size
        ws[counter, 18] = tenant_record.deal_type
        ws[counter, 19] = (tenant_record.lease_structure.present?) ?  tenant_record.lease_structure : 'Full Service'
        ws[counter, 20] = tenant_record.base_rent
        tenant_record.stepped_rents.each do |sr|
          ws[counter, stepped_rent_col] = sr.cost_per_month
          ws[counter, stepped_rent_col+1] = sr.months
          stepped_rent_col+=2
        end
        counter+=1
      end
      ws.save()
      session.drive.batch do
        user_permission = {
            value: 'default',
            type: 'anyone',
            role: 'writer'
        }
        session.drive.create_permission(@file.id, user_permission, fields: 'id')
      end

    # respond_to do |format|
    #   if (params[:tenant_record][:summary].blank?)
    #     session[:search_params] = original_params unless params.has_key? :previous # only if store if it's not a previous requery
    #     #format.json { render json: { type: 'advanced', res: @tenant_records.limit(100).offset(params['tenant_record'][:offset]).order($order), count: @tenant_records.length, params:params } }
    #
    #     format.html  # index.html.erb
    #
    #     format.json { render json: { type: 'advanced', res: tenant_records, count: tenant_records.length, params:params } }
    #   else
    #     format.json { render json: { type: 'advanced', summary: tenant_records.all.first, count: tenant_records.all.first.total_count, params:params } }
    #
    #
    #     format.html { render html }
    #
    #
    #   end
      render :json => {
          :file => @file.id
      }


  end

  def database_sale

    require "google_drive"
    require 'digest/sha1'
    require 'time'
    scope = sales_scope_records_by_params(params[:tenant_record], current_user)
    #if this is the first page than calculate summary
    $order = 'address1'

    original_params = Marshal.load(Marshal.dump(params))

    # if summary, calculate quarters and find avg weighted market effective
    if params[:tenant_record][:summary]
      current = Date.today.beginning_of_quarter
      q1, q2, q3, q4 = (1..4).map { |i| Date.today.beginning_of_quarter.months_ago(i*3) }
      params['avg_weighted_tenant_effective'] = []
      # a = q1_avg.avg_cushman_market_effective.to_f
      #b = a
      q1_avg = scope.where(id: TenantRecord.scoped.lease_term_overlap(q1.end_of_quarter, current.end_of_quarter).select("id")).first
      params['avg_weighted_tenant_effective'] << (cushman_user ? q1_avg.avg_cushman_market_effective.to_f : q1_avg.avg_weighted_market_effective.to_f)

      q2_avg = scope.where(id: TenantRecord.scoped.lease_term_overlap(q2.end_of_quarter, q1.end_of_quarter).select("id")).first
      params['avg_weighted_tenant_effective'] << (cushman_user ? q2_avg.avg_cushman_market_effective.to_f : q2_avg.avg_weighted_market_effective.to_f)

      q3_avg = scope.where(id: TenantRecord.scoped.lease_term_overlap(q3.end_of_quarter, q2.end_of_quarter).select("id")).first
      params['avg_weighted_tenant_effective'] << (cushman_user ? q3_avg.avg_cushman_market_effective.to_f : q3_avg.avg_weighted_market_effective.to_f)

      q4_avg = scope.where(id: TenantRecord.scoped.lease_term_overlap(q4.end_of_quarter, q3.end_of_quarter).select("id")).first
      params['avg_weighted_tenant_effective'] << (cushman_user ? q4_avg.avg_cushman_market_effective.to_f : q4_avg.avg_weighted_market_effective.to_f)

      params['avg_weighted_tenant_effective_quarters'] = ["Current", get_quarter(q1), get_quarter(q2), get_quarter(q3)].reverse
      params['avg_weighted_tenant_effective'].reverse!

      if params[:tenant_record][:cost_display] == 'mo'
        params['avg_weighted_tenant_effective'].each_with_index do |single_avg, index|
          params['avg_weighted_tenant_effective'][index] = single_avg / 12.0
        end
      end

      #params['avg_weighted_tenant_effective'] = [53.0772056141280498,53.9177455557559932,54.4592933213889421,54.4012608930364223].reverse
    end

    if params.has_key? :radius and params[:tenant_record][:summary].blank?
      # no records found but we just need a record with a latitude/longitude pair, so we'll get rid of other parameters that
      # will prevent us from looking for an address
      scope = scope_records_by_params({"search_type" => params[:tenant_record][:search_type], "address1" => params[:tenant_record][:address1], "zipcode" => params[:tenant_record][:zipcode], "q" => params[:tenant_record][:q]}, current_user)
      t = scope.where('tenant_records.latitude is not null and tenant_records.longitude is not null').first

      latitude, longitude = apply_radius(params[:radius], t.latitude, t.longitude)
      params[:tenant_record][:latitude] = latitude
      params[:tenant_record][:longitude] = longitude
      params[:tenant_record].delete(:address1) if params[:tenant_record].has_key? :address1
      params[:tenant_record].delete(:zipcode) if params[:tenant_record].has_key? :zipcode
      params[:tenant_record].delete(:q)  if params[:tenant_record].has_key? :q
      tenant_records = scope_records_by_params params[:tenant_record], current_user
    end

    ####params['is_cushman_user'] = cushman_user
    # @NOTE specifying the table name, otherwise, the field returns sorted as a string, rather then integer
    $order = params[:tenant_record][:order] if (! params[:tenant_record][:order].blank?)


    tenant_records ||= scope




    @summary = tenant_records.all.first

    sale_records = tenant_records
    time = Time.now.getutc
    fileName = Digest::SHA1.hexdigest("#{time}#{@current_user}")
    session = GoogleDrive::Session.from_config("#{Rails.root}/config/google-sheets.json")

    @file = session.drive.copy_file('1xPvNyWzcah6fbf_VlunbE_GDfMG1ufw3Gb2UeLa0MGo', {name: "#{@current_user.id}_temp"}, {})

    # put data to sheet
    ws = session.spreadsheet_by_key(@file.id).worksheets[0]
    counter=2
    sale_records.each do |sale_record|
      ws[counter, 1] = sale_record.id
      ws[counter, 2] = (sale_record.main_image_file_name.present?) ? sale_record.main_image_file_name : '=image("https://maps.googleapis.com/maps/api/streetview?size=350x200&location='+"#{sale_record.latitude},#{sale_record.longitude}"+'&heading=151.78&pitch=-0.76",2)'
      ws[counter, 3] = sale_record.view_type
      ws[counter, 4] = sale_record.address1
      ws[counter, 5] = sale_record.city
      ws[counter, 6] = sale_record.state
      ws[counter, 7] = sale_record.submarket
      ws[counter, 8] = sale_record.property_name
      ws[counter, 9] = sale_record.build_date
      ws[counter, 10] = sale_record.property_type
      ws[counter, 11] = sale_record.class_type
      ws[counter, 12] = sale_record.land_size
      ws[counter, 13] = sale_record.price
      ws[counter, 14] = sale_record.sold_date
      ws[counter, 15] = sale_record.cap_rate
      counter+=1
    end
    ws.save()

    session.drive.batch do
      user_permission = {
          value: 'default',
          type: 'anyone',
          role: 'writer'
      }
      session.drive.create_permission(@file.id, user_permission, fields: 'id')
    end


    # respond_to do |format|
    #   if (params[:tenant_record][:summary].blank?)
    #     session[:search_params] = original_params unless params.has_key? :previous # only if store if it's not a previous requery
    #     #format.json { render json: { type: 'advanced', res: @tenant_records.limit(100).offset(params['tenant_record'][:offset]).order($order), count: @tenant_records.length, params:params } }
    #
    #     format.html  # index.html.erb
    #
    #     format.json { render json: { type: 'advanced', res: tenant_records.paginate(:page => params['tenant_record'][:page].to_i, :per_page => 100).order($order), count: tenant_records.length, params:params } }
    #   else
    #     format.json { render json: { type: 'advanced', summary: tenant_records.all.first, count: tenant_records.all.first.total_count, params:params } }
    #
    #
    #     format.html { render html }
    #
    #
    #   end
    # end

    render :json => {
        :file => @file.id
    }


  end

  protected

  def get_dashboard_query_url(result_hash = { previous: true })
    if result_hash.has_key?(:address1) and result_hash.has_key?(:zipcode)
      result_hash.merge!({:q => result_hash[:address1].to_s + ", " + result_hash[:zipcode].to_s })
    end
    result_hash
  end

  def get_quarter(date)
    "Q" + ((date.month.to_f / 3.to_f).ceil).to_s
  end
end
