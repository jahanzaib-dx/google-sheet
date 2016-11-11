require 'shrimp'

class GeneratePdfReportWorker
  include Sidekiq::Worker
  include SearchControllerUtil
  include CalculatorUtil

  sidekiq_options :queue => :pdf

  def perform(path, criteria, user_id, request=nil, is_cushman_user, template_id)
    @user = User.find(user_id)
    @criteria = criteria
    @tenant_record_params = criteria['tenant_record']
    @path = path
    @request = request

    # get tenant summary
    html = case @criteria['pdf_type']
             when 'single_page'
               single_comp_report @criteria['pdf_id'], is_cushman_user, template_id
             when 'analytics'
               analytics is_cushman_user
             else
               multiple_comp_reports is_cushman_user, template_id
           end

    Shrimp::Phantom.new("http://localhost", {
        :viewport => "1024*768",
        :rendering_time => 15000,
        :margin => '{ bottom: "0.5in" }',
        :format => 'A4' ,
        :zoom => 1,
        :content => html
    }).to_pdf(path)
  end

  protected

  def multiple_comp_reports is_cushman_user, template_id
    @summary = scope_records_by_params(@tenant_record_params.merge!({'address1' => @criteria['address1'], 'zipcode' => @criteria['zipcode'], 'q' => @criteria['q'], 'summary' => true}), @user).all.first
    all = scope_records_by_params(@tenant_record_params.merge!({'address1' => @criteria['address1'], 'zipcode' => @criteria['zipcode'], 'q' => @criteria['q'], 'summary' => false}), @user).limit(100).order('tenant_records.size desc')
    private_record_count = 0

    #six sigma
    sixsigma_results = Hash.new
    all.each do |t|
      private_record_count += 1 if t.private?
      next unless t.protected?
      sixsigma_results[t.id] = sixsigma t
    end

    #remove all private records (looping again, bleh)
    all.reject! { |t| t.private? || t.confidential? }

    # we are working with a single address here
    single_address = (@tenant_record_params['latitude'].blank? and @tenant_record_params['longitude'].blank?) and (@criteria['address1'].present? and @criteria['zipcode'].present?)
    if (single_address)
      @tenant_record_params['longitude'] = all.first.longitude rescue nil
      @tenant_record_params['latitude'] = all.first.latitude rescue nil
    end

    assigned_vars = {
        :private_record_count => 0,
        :user => @user,
        :summary => @summary,
        :all => all,
        :params => @tenant_record_params,
        :sixsigma => sixsigma_results,
        :single_address => single_address,
        :is_cushman_user => is_cushman_user,
        :custom_template => CustomReport.get_template_by_id(template_id)
    }

    build_view(assigned_vars).render :template => 'search/custom_report/multi/report', :layout => 'layouts/report'
  end

  def single_comp_report(id, is_cushman_user, template_id)
    @summary = scope_records_by_params(@tenant_record_params.merge!({'address1' => @criteria['address1'], 'zipcode' => @criteria['zipcode'], 'q' => @criteria['q'], 'summary' => true}), @user).all.first
    tenant_record = if @user.has_admin?
                      TenantRecord.protect_view(@user).scoped.find id
                    else
                      scope_protect_view_office_user(@tenant_record_params, @user).find id
                    end
    # Fetch values for output metrics
    @financial_detail = calculate(tenant_record, 'TenantEffective')[:summary]

    @custom_template = CustomReport.get_template_by_id(template_id)
    sixsigma_results = tenant_record.protected? ? sixsigma(tenant_record) : nil
    assigned_vars = {:user => @user, :sixsigma => sixsigma_results, :record => tenant_record, :summary => @summary, :is_cushman_user => is_cushman_user, :custom_template => @custom_template, :financial_detail => @financial_detail}
    build_view(assigned_vars).render :template => 'search/custom_report/single/custom_single_report', :layout => 'layouts/report'
  end

  def analytics(is_cushman_user)
    assigned_vars = Hash.new
    scoped_records = scope_records_by_params(@tenant_record_params.merge!({'address1' => @criteria['address1'], 'zipcode' => @criteria['zipcode'], 'q' => @criteria['q'], 'summary' => false, 'analytics_view' => true }), @user)

    # asset comparison
    if(@criteria['asset_comparison'].present?)
      if is_cushman_user
        assigned_vars[:asset_comparison] = scoped_records
        .select("COALESCE(SUM((tenant_records.cushman_net_effective_per_sf * tenant_records.size)::decimal)/SUM(tenant_records.size)::decimal, 0) AS average_net_effective_per_sf " +
                    ", COALESCE(SUM((tenant_records.data->'landlord_effective_per_annum')::decimal)/SUM(tenant_records.size)::decimal,0) AS avg_landlord_effective_per_annum " +
                    ",tenant_records.address1")
        .group('tenant_records.address1')
        .order('average_net_effective_per_sf desc')
        .all
      else
        assigned_vars[:asset_comparison] = scoped_records
        .select("COALESCE(SUM((tenant_records.data->'tenant_effective_per_annum')::decimal)/SUM(tenant_records.size)::decimal, 0) AS average_net_effective_per_sf " +
                    ", COALESCE(SUM((tenant_records.data->'landlord_effective_per_annum')::decimal)/SUM(tenant_records.size)::decimal,0) AS avg_landlord_effective_per_annum " +
                    ",tenant_records.address1")
        .group('tenant_records.address1')
        .order('average_net_effective_per_sf desc')
        .all
      end

      assigned_vars[:bars_per_page] = 6
    end

    scoped_min_date = scoped_records.minimum("lease_commencement_date")
    scoped_max_date = scoped_records.maximum("lease_commencement_date")
    min_date = Date.new(scoped_min_date.year, 1, 1)
    max_date = Date.new(scoped_max_date.year, 12,-1)

    hash = Hash.new
    landlord_hash = Hash.new

    while(min_date < max_date)
      q1, q2, q3, q4 = (0..3).map { |i| min_date.beginning_of_quarter + ((i*3).months) }

      q1_ids = scoped_records.lease_term_overlap(q1.beginning_of_quarter, q1.end_of_quarter).to_a
      q2_ids = scoped_records.lease_term_overlap(q2.beginning_of_quarter, q2.end_of_quarter).to_a
      q3_ids = scoped_records.lease_term_overlap(q3.beginning_of_quarter, q3.end_of_quarter).to_a
      q4_ids = scoped_records.lease_term_overlap(q4.beginning_of_quarter, q4.end_of_quarter).to_a

      q1_aggr = q1_landlord_aggr = 0.00
      landlord_numerator = numerator = denominator = 0.00
      if q1_ids.present?
        q1_ids.each do |record|
          if is_cushman_user
            numerator += (record.cushman_net_effective_per_sf * record.size)
          else
            numerator += (record.net_effective_per_sf * record.size)
          end
          if @criteria['ma_landlord_concession'].present?
            landlord_numerator += (record.landlord_concessions_per_sf * record.size)
          end
          denominator += record.size
        end
        q1_aggr = (numerator / denominator) rescue 0.00
        q1_landlord_aggr = (landlord_numerator / denominator) rescue 0.00
      end

      q2_aggr = q2_landlord_aggr = 0.00
      landlord_numerator = numerator = denominator = 0.00
      if q2_ids.present?
        q2_ids.each do |record|
          if is_cushman_user
            numerator += (record.cushman_net_effective_per_sf * record.size)
          else
            numerator += (record.net_effective_per_sf * record.size)
          end
          if @criteria['ma_landlord_concession'].present?
            landlord_numerator += (record.landlord_concessions_per_sf * record.size)
          end
          denominator += record.size
        end
        q2_aggr = (numerator / denominator) rescue 0.00
        q2_landlord_aggr = (landlord_numerator / denominator) rescue 0.00
      end

      q3_aggr = q3_landlord_aggr = 0.00
      landlord_numerator = numerator = denominator = 0.00
      if q3_ids.present?
        q3_ids.each do |record|
          if is_cushman_user
            numerator += (record.cushman_net_effective_per_sf * record.size)
          else
            numerator += (record.net_effective_per_sf * record.size)
          end
          if @criteria['ma_landlord_concession'].present?
            landlord_numerator += (record.landlord_concessions_per_sf * record.size)
          end
          denominator += record.size
        end
        q3_aggr = (numerator / denominator) rescue 0.00
        q3_landlord_aggr = (landlord_numerator / denominator) rescue 0.00
      end

      q4_aggr = q4_landlord_aggr = 0.00
      landlord_numerator = numerator = denominator = 0.00
      if q4_ids.present?
        q4_ids.each do |record|
          if is_cushman_user
            numerator += (record.cushman_net_effective_per_sf * record.size)
          else
            numerator += (record.net_effective_per_sf * record.size)
          end
          if @criteria['ma_landlord_concession'].present?
            landlord_numerator += (record.landlord_concessions_per_sf * record.size)
          end
          denominator += record.size
        end
        q4_aggr = (numerator / denominator) rescue 0.00
        q4_landlord_aggr = (landlord_numerator / denominator) rescue 0.00
      end

      hash.merge!({"#{min_date.year}-Q1" => q1_aggr.round(2).to_s })
      hash.merge!({"#{min_date.year}-Q2" => q2_aggr.round(2).to_s })
      hash.merge!({"#{min_date.year}-Q3" => q3_aggr.round(2).to_s })
      hash.merge!({"#{min_date.year}-Q4" => q4_aggr.round(2).to_s })

      landlord_hash.merge!({"#{min_date.year}-Q1" => q1_landlord_aggr.round(2).to_s })
      landlord_hash.merge!({"#{min_date.year}-Q2" => q2_landlord_aggr.round(2).to_s })
      landlord_hash.merge!({"#{min_date.year}-Q3" => q3_landlord_aggr.round(2).to_s })
      landlord_hash.merge!({"#{min_date.year}-Q4" => q4_landlord_aggr.round(2).to_s })

      min_date += 1.year
    end

    assigned_vars[:market_net_effective] = hash.delete_if { |k, v| v == "0.0" } if @criteria['ma_net_effective'].present?

    assigned_vars[:market_landlord_concessions] = landlord_hash.delete_if { |k, v| v == "0.0" } if @criteria['ma_landlord_concession'].present?

    #temp = scoped_records
    #.except(:group)
    #.group('EXTRACT(year FROM lease_commencement_date)')
    #.average(:cushman_net_effective_per_sf)

    if is_cushman_user
      assigned_vars[:industry_comparison] = scoped_records
      .select('EXTRACT( year FROM lease_commencement_date) as year, EXTRACT(month FROM lease_commencement_date) as month, cushman_net_effective_per_sf as net_effective_per_sf')
      .all if @criteria['industry_comparison'].present?
    else
      assigned_vars[:industry_comparison] = scoped_records
      .select('EXTRACT( year FROM lease_commencement_date) as year, EXTRACT(month FROM lease_commencement_date) as month, net_effective_per_sf')
      .all if @criteria['industry_comparison'].present?
    end

    #assigned_vars[:industry_sic_code] = if @tenant_record_params['industry_sic_code_id'].present?
    #                                      industry = IndustrySicCode.find_by_id(@tenant_record_params['industry_sic_code_id'])
    #                                      "#{industry.value} - #{industry.description}"
    #                                    end

    assigned_vars[:industry_type] = if @tenant_record_params['industry_type'].present?
                                      @tenant_record_params['industry_type']
                                    end


    assigned_vars[:params] = @tenant_record_params.merge('include_criteria' => 'true') if @criteria['include_criteria'].present?
    assigned_vars[:all] = scoped_records
    assigned_vars[:user] = @user
    assigned_vars[:is_cushman_user] = is_cushman_user

    build_view(assigned_vars).render :template => 'search/analytics', :layout => 'layouts/report'
  end

  def sixsigma(tenant_record)
    {
        :net_effective => get_sixsigma(tenant_record.id, 'net_effective_per_sf',
                                       @summary.avg_net_effective_per_sf,
                                       @summary.tile_net_effective_per_sf).selected_six_sigma,

        :landlord_concessions => get_sixsigma(tenant_record.id, 'landlord_concessions_per_sf',
                                              @summary.avg_landlord_concessions_per_sf,
                                              @summary.tile_landlord_concessions_per_sf).selected_six_sigma
    }
  end

  def build_view(assign_vars)
    Tenantrex::Application.routes.default_url_options = { :host => 'localhost' }
    controller = SearchController.new
    controller.request = ActionDispatch::Request.new @request
    view = ActionView::Base.new(Tenantrex::Application.config.paths["app/views"].first, assign_vars, controller)

    view.class_eval do
      include ApplicationHelper
      include Tenantrex::Application.routes.url_helpers
    end

    view
  end
end
