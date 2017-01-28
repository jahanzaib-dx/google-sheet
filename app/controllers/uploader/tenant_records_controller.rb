class Uploader::TenantRecordsController < ApplicationController

  #include CalculatorUtil
  #include CushmanCalculationEngine
  include GoogleGeocoder

  before_filter :authenticate_user!

  layout 'uploader'

  def index
  end

  def new
    @tenant_record = TenantRecord.new
  end

  def create

    @property_type = params[:property_type_switch]
    if @property_type == 'lease_comps'

      @tenant_record = TenantRecord.new(tenant_record_params)

      #@tenant_record.office = current_user.account.office
      @tenant_record.gross_free_rent = false unless params[:tenant_record][:gross_free_rent]
      @tenant_record.is_tenant_improvement = false unless params[:tenant_record][:is_tenant_improvement]


      if @tenant_record.base_rent_type == 'monthly' && !(params[:tenant_record][:stepped_rents_attributes].present?)
        @tenant_record.base_rent = @tenant_record.base_rent.to_f * 12.0
      end
      @tenant_record.lease_commencement_date = Date.strptime(params[:tenant_record][:lease_commencement_date], "%m/%d/%Y")


      puts "before calling save_tenant_record ------------"
      save_tenant_record @tenant_record


    elsif @property_type == 'sales_comps'
      @sale_record = SaleRecord.new(sale_record_params)
      @sale_record.is_sales_record = (params[:sale_record][:is_sales_record] == 'yes' ? true : false)
      if params[:sale_record][:build_date].present?
        @sale_record.build_date = Date.strptime(params[:sale_record][:build_date], "%m/%d/%Y")
      end
      @sale_record.sold_date = Date.strptime(params[:sale_record][:sold_date], "%m/%d/%Y")

      puts "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
      puts @sale_record.custom

      ## find lat/lon if it hasn't been done already
      begin
        geocode_setup(@sale_record)
      rescue Exception => exception
        Rails.logger.info("Exception while GeoCoding ... ")
      end

      @sale_record.save

    elsif @property_type == 'custom_data'
      @custom_record = CustomRecord.new(custom_record_params)
      @custom_record.is_existing_data_set = (params[:custom_record][:is_existing_data_set] == 'yes' ? true : false)
      @custom_record.is_geo_coded = false unless params[:custom_record][:is_geo_coded]

      if @custom_record.is_geo_coded
        ## find lat/lon if it hasn't been done already
        begin
          geocode_setup(@custom_record)
        rescue Exception => exception
          Rails.logger.info("Exception while GeoCoding ... ")
        end
      end
      @custom_record.save
    end

    # respond_to do |format|
    #   if save_tenant_record @tenant_record
    #     format.html { redirect_to tenant_record_path(@tenant_record) }
    #     format.json { render json: @tenant_record }
    #   else
    #     format.html { render action: 'new' }
    #     format.json { render json: @tenant_record.errors, status: :unprocessable_entity }
    #   end
    # end
  end

  def show
    @tenant_record = TenantRecord.find(params[:id])
  end

  def display_custom_record
    @custom_record = CustomRecord.find(params[:tenant_record_id])
  end

  def display_sales_comp
    @sale_record = SaleRecord.find(params[:tenant_record_id])
  end

  private

  def save_tenant_record(trec)

    if params[:lease_structure]
      trec.set_lease_structure LeaseStructure.new lease_structure_params
    # elsif params[:predefined_lease_struct].present?
    #   trec.set_lease_structure LeaseStructure.find params[:predefined_lease_struct]
    end

    ## find lat/lon if it hasn't been done already
    if trec.longitude.blank? or trec.latitude.blank?
      result = validate_address_google(trec)

      if result.has_key? :coords
        trec.latitude = result[:coords][:latitude]
        trec.longitude = result[:coords][:longitude]
      end

      if result.has_key? :updates
        trec.latitude = result[:updates][:latitude]
        trec.longitude = result[:updates][:longitude]
        trec.zipcode = result[:updates][:zipcode]
      end
    end

    trec.is_stepped_rent = true if params[:tenant_record][:stepped_rents_attributes].present?

    custom_allowance_attributes = {}
    if params[:tenant_record][:has_additional_tenant_cost] && params[:additional_tenant_cost_tmp].to_i > 0
      tenant_cost_sum = 0.0
      custom_allowance_attributes.merge!("additional_tenant_cost_tmp" => params[:additional_tenant_cost_tmp].to_i)
      (1..params[:additional_tenant_cost_tmp].to_i).to_a.each do |count|
        tenant_cost_sum += params[:additional_cost][:tenant]["#{count}"].to_f
        custom_allowance_attributes.merge!("additional_cost_tenant_#{count}" => params[:additional_cost][:tenant]["#{count}"].to_f)
      end
      trec.additional_tenant_cost = tenant_cost_sum
    end

    if params[:tenant_record][:has_additional_ll_allowance] && params[:additional_ll_cost_tmp].to_i > 0
      ll_cost_sum = 0.0
      custom_allowance_attributes.merge!("additional_ll_cost_tmp" => params[:additional_ll_cost_tmp].to_i)
      (1..params[:additional_ll_cost_tmp].to_i).to_a.each do |count|
        ll_cost_sum += params[:additional_cost][:ll]["#{count}"].to_f
        custom_allowance_attributes.merge!("additional_cost_ll_#{count}" => params[:additional_cost][:ll]["#{count}"].to_f)
      end
      trec.additional_ll_allowance = ll_cost_sum
    end

    if custom_allowance_attributes
      trec.set_custom_allowance_attributes(custom_allowance_attributes)
    end

    ## net effective calculations TODO: can we use the worker code for this?
    #results = calculate(trec)
    #attributes = pull_attributes(results, trec)

    # if cushman_user && params[:tenant_record][:stepped_rents_attributes].present?
    #   cushman_results = retrieve_cushman_metrics(trec)
    #   attributes.merge!(cushman_net_effective_per_sf: cushman_results[:net_effective_rent])
    # end

    trec.validate_all = true
    #trec.assign_attributes(attributes) # pull attributes from CalculatorUtil
    puts "ccccccccccccccccccccccccccccccccccccccccccccc"
    puts trec.valid? ? "true":"false"

    unless(trec.save)
      Rails.logger.debug trec.errors.full_messages
    end

  end

  def geocode_setup(trec)
    result = validate_address_google(trec, true)
    if result.has_key? :coords
      trec.latitude = result[:coords][:latitude]
      trec.longitude = result[:coords][:longitude]
    end

    if result.has_key? :updates
      trec.latitude = result[:updates][:latitude]
      trec.longitude = result[:updates][:longitude]
      trec.zipcode = result[:updates][:zipcode]
    end
  end


  def tenant_record_params
    params[:tenant_record].permit(
        :data,                        # hstore of custom fields
        :interest_rate,
        :discount_rate,               #
        :lease_structure_description,
        :address1,                    # required
        :base_rent,                   # required
        :cam_cost,                    # required
        :city,                        # required
        :class_type,                  # required
        :company,                     # required
        :company_logo,
        :comments,
        :comp_type,                   # required
        :contact,                     # required
        :contact_email,               # required
        :contact_phone,               # required
        :discount_percentage,         # required
        :electrical_expense_cost,     # required
        :escalation,                  # required
        :free_rent_total,
        :free_rent,
        #:industry_sic_code_id,        # required
        :industry_type,
        :janitorial_cost,             # required
        :latitude,                    # required
        :landlord_concessions_per_sf, # calculated by net_effective_calculator
        :landlord_margins,            # calculated by net_effective_calculator
        :landlord_effective_rent,     # calculated by net_effective_calculator
        :lease_commencement_date,     # required
        :lease_structure,             # required
        :lease_term_months,           # required
        :lease_type,                  # required
        :location_type,               # required
        :longitude,                   # required
        :mongoid,                     # customer unique identifier
        :net_effective_per_sf,        # calculated by neteffective_calculator
        :operator_expense_cost,       # required
        :property_name,
        :property_type,               # required
        :real_estate_tax_cost,        # required
        :size,                        # required
        :state,                       # required
        :submarket,
        :suite,
        :tenant_improvement,          # required
        :tenant_ti_cost,
        :version,
        :view_type,                   # required
        :zipcode,                     # required, 5 digit
        :zipcode_plus,                 # required,4 digit
        :expenses,
        :custom,
        :main_image,
        :delete_image,
        :delete_company_image,
        :avg_base_rent_per_annum_by_sf,
        :cushman_net_effective_per_sf,
        :is_stepped_rent,
        :additional_ll_allowance,
        :additional_tenant_cost,
        :gross_free_rent,
        :comp_view_type,
        :comp_data_type,
        :deal_type,
        :fixed_escalation,
        :base_rent_type,
        :rent_escalation_type,
        :free_rent_type,
        :is_tenant_improvement,
        :has_additional_tenant_cost,
        :has_additional_ll_allowance,
        :lease_structure_expenses_attributes,
        :stepped_rents_attributes => [:months	, :cost_per_month]
    )
  end

  def sale_record_params
    params.require(:sale_record).permit(:is_sales_record, :land_size_identifier, :view_type,
                                :address1, :city, :state, :land_size, :price, :cap_rate,:submarket, :custom,
                                :latitude, :longitude, :zipcode, :zipcode_plus, :office_id,
                                :property_name, :build_date, :property_type, :class_type, :sold_date
    )
  end

  def custom_record_params
    params.require(:custom_record).permit(:is_existing_data_set, :is_geo_coded, :name,
                                  :address1, :city, :state, :latitude, :longitude, :zipcode, :zipcode_plus,
                                  custom_record_properties_attributes: [:key, :value])
  end

  def lease_structure_params
    #params[:lease_structure].permit(:name, :description, :discount_rate, :interest_rate, :lease_structure_expenses_attributes)
    params.require(:lease_structure).permit!
  end




end