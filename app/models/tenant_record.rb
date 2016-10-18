class TenantRecord < ActiveRecord::Base
  include ConditionalValidations
  ####serialize :data, ActiveRecord::Coders::Hstore
  acts_as_paranoid

  #belongs_to :ownership
  has_many :ownership

  before_restore :add_to_all_office_agreements
  before_destroy :remove_from_all_office_agreements
  after_create :add_to_all_office_agreements
  after_create :do_net_effective_calculator
  after_find :protect_record
  before_save :default_values
  before_validation :default_values
  after_save :populate_lookup_tables

  has_and_belongs_to_many :agreements

  has_many :comp_requests
  belongs_to :user
  has_one :flaged_comp, :foreign_key => :comp_id

  def complete_address
    [address1, city, state, zipcode].join(", ")
  end

  ###belongs_to :office
  #belongs_to :industry_sic_code
  ###belongs_to :team

  has_many :stepped_rents, :dependent => :destroy
  accepts_nested_attributes_for :stepped_rents, :allow_destroy => true

  has_many :tenant_record_images
  has_attached_file :main_image,
    styles: { edit: "200x200^", detail_page: "306" },
    :url => '/system/:class/:id/:style/:filename',
    :path => ':rails_root/public:url'

  has_attached_file :company_logo,
                    styles: { edit: "200x200^", detail_page: "306" },
                    :url => '/system/:class/:id/:style/:filename',
                    :path => ':rails_root/public:url'

  has_and_belongs_to_many :lookup_address_zipcodes
  has_and_belongs_to_many :lookup_companies
  has_and_belongs_to_many :lookup_property_names
  has_and_belongs_to_many :lookup_submarkets

  #************************* Marketrex ***************************
##  COMP_DATA_TYPE        = %w[lease_comps sales_comps custom_data]
##  NEW_PROPERTY_TYPE     = PropertyType.property_type_list
##  DEAL_TYPE             = ["new", "renewal", "expansion", "sublease", "blend & extend"]
##  NEW_VIEW_TYPE         = %w[internal external]
##  LEASE_STRUTURE        = ["Full Service", "Modified Gross", "NNN"]
  #**************************************************************

  CLASS_TYPE           = %w[a b c]
  COMP_TYPE            = %w[market internal]
  VIEW_TYPE            = %w[private confidential network public]
  LOCATION_TYPE        = %w[branch headquarters]
  PROPERTY_TYPE        = %w[office industrial retail flex]
  REQUIRED_FIELDS = %w[company address1 suite city state zipcode
  base_rent class_type comp_type contact contact_email contact_phone lease_type
  escalation free_rent industry_sic_code_id lease_commencement_date lease_term_months
  property_type size tenant_improvement tenant_ti_cost discount_percentage
  view_type comments property_name submarket industry_type]

  validates_associated :office
  #validates_associated :industry_sic_code
  validates_associated :stepped_rents
  validate :stepped_rents_equal_term_months
  conditionally_validate :address1,
            :presence => true
  conditionally_validate :city,
            :presence => true
  conditionally_validate :state,
            :presence => true
  conditionally_validate :base_rent,
             :presence => true, :numericality => true, :unless => 'stepped_rents.any?'
  conditionally_validate :class_type,
             :presence => true#, :inclusion => { :in => CLASS_TYPE }, :allow_nil => true
  conditionally_validate :company,
            :presence => true
  conditionally_validate :comp_type,
            :presence => true#, :inclusion => { :in => COMP_TYPE }
  conditionally_validate :escalation,
            :presence => true, :numericality => { :greater_than_equal_to => 0, :less_than_equal_to => 100 }, :allow_nil => true, :unless => 'stepped_rents.any?'
  conditionally_validate :lease_commencement_date,
            :presence => true
  conditionally_validate :property_type,                                                      # required
            :presence => true#, :inclusion => { :in => PROPERTY_TYPE }
  conditionally_validate :size,                                                               # required
            :presence => true, :numericality => { :only_integer => true, :greater_than => 0 }
  conditionally_validate :tenant_improvement,                                                 # required, tenant improvements costs, landlord's expense
            :numericality => true, :allow_nil => true
  conditionally_validate :view_type,                                                          # required
            :presence => true#, :inclusion => { :in => VIEW_TYPE }
  conditionally_validate :tenant_ti_cost,                                                     # tenant's tenant improvements
            :numericality => true, :allow_nil => true
  conditionally_validate :version,                                                            # versions
            :numericality => { :only_integer => true }, :allow_nil => true                           # required
  conditionally_validate :latitude,
            :numericality => true, :allow_nil => true
  conditionally_validate :longitude,
            :numericality => true, :allow_nil => true

  # Calculated by Net Effectived Calculator
  conditionally_validate :landlord_concessions_per_sf,
            :numericality => true
  conditionally_validate :landlord_margins,
            :numericality => true
  conditionally_validate :landlord_effective_rent,
            :numericality => true
  conditionally_validate :lease_term_months,
            :numericality => { :only_integer => true, :greater_than => 0 }, presence: true
  conditionally_validate :net_effective_per_sf,
            :numericality => true

  conditionally_validate :main_image, :attachment_content_type => { :content_type => /\Aimage\/.*\Z/ }
  conditionally_validate :company_logo, :attachment_content_type => { :content_type => /\Aimage\/.*\Z/ }
  #validates_attachment_content_type :main_image, :content_type => /\Aimage\/.*\Z/

  validate :validate_stepped_rents

  def validate_stepped_rents
    if stepped_rents.any?
      stepped_months = stepped_rents.inject(0){|count, r| count + r.months.to_i }
      if stepped_months != lease_term_months
        errors.add(:stepped_rents, "Stepped Rent Months: #{stepped_months}.")
      else
        true
      end
    end
  end


  attr_reader :lease_structure,
              :lease_structure_id,
    :operator_expense_cost,
    :real_estate_tax_cost,
    :electrical_expense_cost,
    :cam_cost,
    :janitorial_cost

  before_validation {
    main_image.clear if delete_image == '1'
    company_logo.clear if delete_company_image == '1'
  }
  attr_accessor :delete_image, :delete_company_image





  scope :address_only, lambda { |office_id = nil|
    office_scope = (!office_id.nil?) ? ", " + office_id.to_s + " as in_scope_office_id" : ""
    select("tenant_records.id, company, submarket, property_name,property_type, comp_type, view_type, zipcode, city, state, address1" + office_scope + ", 'address_only' as in_scope ")
	#.group('tenant_records.id, tenant_records.address1, tenant_records.zipcode')
  }

  scope :team, lambda { |team_id| where("team_id = ?", team_id) }

  scope :protect_view, lambda { |user = nil|

    #office_scope = (!user.has_trex_admin?) ? ", " + user.account.office_id.to_s + " as in_scope_office_id" : ""
    #team_scope = (user.account.teams.present?) ? ",'" + user.account.teams.collect { |t| t.id }.join(',') + "' as in_scope_team_ids" : ""
    #user_scope = if user.has_trex_admin?
    #               ", 'admin' as user_scope"
    #             elsif user.has_analyst?
    #               ", 'analyst' as user_scope"
    #             elsif user.has_broker?
    #               ", 'broker' as user_scope"
    #             else
    #               ""
    #             end

    select(
      "tenant_records.id, " +
      "tenant_records.lease_commencement_date, " +
      "tenant_records.address1, " +
      "tenant_records.suite, " +
      "tenant_records.city, " +
      "tenant_records.state, " +
      "tenant_records.zipcode, " +
      "tenant_records.zipcode_plus, " +
      "tenant_records.size, " +
      "tenant_records.is_stepped_rent, " +
      "tenant_records.data->'first_year_base_rent' as base_rent, " +
      "tenant_records.class_type, " +
      "tenant_records.comp_type, " +
      "tenant_records.comments, " +
      "tenant_records.contact, " +
      "tenant_records.contact_email, " +
      "tenant_records.contact_phone, " +
      "tenant_records.escalation, " +
      "tenant_records.free_rent_total as free_rent, " +
      "tenant_records.free_rent_total, " +
      "tenant_records.data->'fs_equivalent' as fs_equivalent, " +
      "COALESCE((tenant_records.data->'average_annual_rent')::decimal / (tenant_records.size)::decimal,0) as aggr_annual_rent_by_sf, " +
      "tenant_records.data->'leasestructure_expenses_insurance_cost' as insurance_cost, " +
      "tenant_records.data->'leasestructure_expenses_janitorial_cost' as janitorial_cost, " +
      "tenant_records.latitude, " +
      "tenant_records.longitude, " +
      "tenant_records.lease_commencement_date, " +
      "tenant_records.data->'leasestructure_name' as lease_structure, " +
      "tenant_records.lease_term_months / 12 as lease_term_years, " +
      "tenant_records.lease_term_months, " +
      "tenant_records.lease_type, " +
      "tenant_records.location_type, " +
      "tenant_records.net_effective_per_sf, " +
      "tenant_records.cushman_net_effective_per_sf, " +
      "tenant_records.property_type, " +
      "tenant_records.property_name, " +
      "tenant_records.submarket, " +
      "tenant_records.data->'leasestructure_expenses_real_estate_tax_cost' as real_estate_tax_cost, " +
      "tenant_records.tenant_improvement, " +
      "tenant_records.tenant_ti_cost, " +
      "tenant_records.data->'leasestructure_expenses_operating_expense_cost' as operator_expense_cost, " +
      "tenant_records.data->'leasestructure_expenses_cam_cost' as cam_cost, " +
      "COALESCE(COALESCE((tenant_records.data->'leasestructure_expenses_electrical_expense_cost')::decimal, (tenant_records.data->'leasestructure_expenses_electric_cost')::decimal,(tenant_records.data->'leasestructure_expenses_utilities_cost')::decimal), 0) AS electrical_expense_cost, " +
      "tenant_records.company, " +
      #"tenant_records.industry_sic_code_id, " +
      "tenant_records.industry_type, " +
      "tenant_records.view_type, " +
      "tenant_records.office_id, " +
      "tenant_records.team_id, " +
      "tenant_records.data, " +
      "tenant_records.main_image_file_name, " +
      "tenant_records.company_logo_file_name, " +
      "tenant_records.main_image_updated_at, " +
      "tenant_records.company_logo_updated_at, " +
      ###"offices.firm_id AS firm_id,
	  ###firms.name AS firm_name, " +
      ###"offices.name AS office_name, offices.logo_image_file_name AS office_logo_image_file_name " +
      #"industry_sic_codes.value AS industry_sic_code_id," +
      #"industry_sic_codes.description AS industry_sic_code_description" +
      ####office_scope +
      ####team_scope +
      ####user_scope +
      ###", 0 as editable" +
	  " 0 as editable" +
      ", 'protect_view' as in_scope "
    )
    ####.joins({ :office => :firm })
    ####.group('tenant_records.id, tenant_records.address1, offices.firm_id, offices.name, offices.logo_image_file_name, firms.name')
    #.joins(:industry_sic_code)
    #.group('tenant_records.id, tenant_records.address1, offices.firm_id, offices.name, offices.logo_image_file_name, industry_sic_codes.value, industry_sic_codes.description, firms.name')
  }


  scope :six_sigma, lambda { | fieldname = nil, avg = "", tile = "" |
    fieldname ||= "net_effective_per_sf"
    tile ||= 1
    avg  ||= 0
    tile_is  = tile.to_s + " as the_tile"
    avg_is   = avg.to_s + " as the_avg"
    field_is = "'#{fieldname.to_s}' as the_field"
    select(
      [tile_is, avg_is, field_is].join(', ') +
      ( ", tenant_records." + fieldname ) +
      ", 'six' AS selected_six_sigma" +
      ", 'six_sigma' as in_scope "
    )
  }

  scope :summary,  -> {select(
    "count(distinct tenant_records.id) as total_count, " +

    # Averages
    "COALESCE(SUM((tenant_records.data->'first_year_base_rent')::decimal * tenant_records.size)/SUM(tenant_records.size)::decimal,0) AS avg_first_year_base_rent, " +
    "COALESCE(SUM((tenant_records.data->'fs_equivalent')::decimal * tenant_records.size)/SUM(tenant_records.size)::decimal,0) AS avg_fs_equivalent, " +

    "COALESCE(SUM((tenant_records.data->'tenant_effective_per_annum')::decimal)/SUM(tenant_records.size)::decimal, 0) AS avg_net_effective_per_sf, " +
    "COALESCE(SUM((tenant_records.data->'landlord_effective_per_annum')::decimal)/SUM(tenant_records.size)::decimal,0) AS avg_landlord_effective_per_annum, " +
    "COALESCE(SUM(tenant_records.landlord_concessions_per_sf * tenant_records.size)/SUM(tenant_records.size), 0) AS avg_landlord_concessions_per_sf, " +
    "COALESCE(AVG(tenant_records.size), 0) AS avg_size, " +
    "COALESCE(AVG(tenant_records.lease_term_months / 12), 0) AS avg_lease_term_years, " +
    "COALESCE(AVG((tenant_records.data->'leasestructure_expenses_real_estate_tax_cost')::decimal), 0) AS avg_taxes, " +
    "COALESCE(AVG((tenant_records.data->'leasestructure_expenses_operating_expense_cost')::decimal), 0) AS avg_operating_expenses, " +
    "COALESCE(AVG((tenant_records.data->'leasestructure_expenses_cam_cost')::decimal), 0) AS avg_cam, " +
    "AVG(COALESCE(COALESCE((tenant_records.data->'leasestructure_expenses_electrical_expense_cost')::decimal, (tenant_records.data->'leasestructure_expenses_electric_cost')::decimal,(tenant_records.data->'leasestructure_expenses_utilities_cost')::decimal), 0)) AS avg_electric, " +
    "COALESCE(AVG((tenant_records.data->'leasestructure_expenses_janitorial_cost')::decimal), 0) AS avg_janitorial, " +
    "COALESCE(AVG((tenant_records.data->'leasestructure_expenses_insurance_cost')::decimal), 0) AS avg_insurance, " +

    "COALESCE(SUM(tenant_records.tenant_improvement * tenant_records.size)/SUM(tenant_records.size), 0) AS avg_tenant_improvement, " +
    "COALESCE(AVG(tenant_records.free_rent_total), 0) AS avg_free_rent, " +
    "COALESCE(SUM((tenant_records.data->'average_annual_rent')::decimal) / (SUM(tenant_records.size)::decimal), 0) AS weighted_avg_annual_rent_by_sf, " +
    "COALESCE(AVG(tenant_records.escalation), 0) AS avg_escalation " +


    # Percentage of net effective
    ", COALESCE((CASE WHEN SUM(tenant_records.net_effective_per_sf) > 0 THEN (SUM((tenant_records.data->'first_year_base_rent')::decimal) / SUM(tenant_records.net_effective_per_sf)) ELSE 0 END), 0) AS percentage_base_rent" +
    ", COALESCE((CASE WHEN SUM(tenant_records.net_effective_per_sf) > 0 THEN ( SUM((tenant_records.data->'leasestructure_expenses_real_estate_tax_cost')::decimal) / SUM(tenant_records.net_effective_per_sf)) ELSE 0 END), 0) AS percentage_real_estate_tax_cost" +
    ", COALESCE((CASE WHEN SUM(tenant_records.net_effective_per_sf) > 0 THEN ( SUM((tenant_records.data->'leasestructure_expenses_operating_expense_cost')::decimal) / SUM(tenant_records.net_effective_per_sf)) ELSE 0 END), 0) AS percentage_operator_expense_cost" +
    ", COALESCE((CASE WHEN SUM(tenant_records.net_effective_per_sf) > 0 THEN ( SUM((tenant_records.data->'leasestructure_expenses_cam_cost')::decimal) / SUM(tenant_records.net_effective_per_sf)) ELSE 0 END), 0) AS percentage_cam_cost" +
    ", COALESCE((CASE WHEN SUM(tenant_records.net_effective_per_sf) > 0 THEN ( SUM(COALESCE(COALESCE((tenant_records.data->'leasestructure_expenses_electrical_expense_cost')::decimal, (tenant_records.data->'leasestructure_expenses_electric_cost')::decimal,(tenant_records.data->'leasestructure_expenses_utilities_cost')::decimal), 0)) / SUM(tenant_records.net_effective_per_sf)) ELSE 0 END), 0) AS percentage_electrical_expense_cost" +
    ", COALESCE((CASE WHEN SUM(tenant_records.net_effective_per_sf) > 0 THEN ( SUM((tenant_records.data->'leasestructure_expenses_janitorial_cost')::decimal) / SUM(tenant_records.net_effective_per_sf)) ELSE 0 END), 0) AS percentage_janitorial_cost" +
    ", COALESCE((CASE WHEN SUM(tenant_records.net_effective_per_sf) > 0 THEN ( SUM((tenant_records.data->'leasestructure_expenses_insurance_cost')::decimal) / SUM(tenant_records.net_effective_per_sf)) ELSE 0 END), 0) AS percentage_insurance_cost" +

    # For Six Sigma
    ", COALESCE(STDDEV(tenant_records.net_effective_per_sf), 0) AS tile_net_effective_per_sf " +
    ", COALESCE(STDDEV(tenant_records.landlord_concessions_per_sf), 0) AS tile_landlord_concessions_per_sf " +
    ", COALESCE(STDDEV(tenant_records.lease_term_months / 12), 0) AS tile_lease_term_years " +
    ", COALESCE(STDDEV((tenant_records.data->'leasestructure_expenses_real_estate_tax_cost')::decimal), 0) AS tile_real_estate_tax_cost " +
    ", COALESCE(STDDEV((tenant_records.data->'leasestructure_expenses_operating_expense_cost')::decimal), 0) AS tile_operator_expense_cost " +
    ", COALESCE(STDDEV((tenant_records.data->'leasestructure_expenses_cam_cost')::decimal), 0) AS tile_cam " +
    ", STDDEV(COALESCE(COALESCE((tenant_records.data->'leasestructure_expenses_electrical_expense_cost')::decimal, (tenant_records.data->'leasestructure_expenses_electric_cost')::decimal,(tenant_records.data->'leasestructure_expenses_utilities_cost')::decimal), 0)) AS tile_electrical_expenses_cost " +
    ", COALESCE(STDDEV((tenant_records.data->'leasestructure_expenses_janitorial_cost')::decimal), 0) AS tile_janitorial_cost " +
    ", COALESCE(STDDEV((tenant_records.data->'leasestructure_expenses_insurance_cost')::decimal), 0) AS tile_insurance_cost " +
    ", COALESCE(STDDEV(tenant_records.tenant_improvement), 0) AS tile_tenant_improvement " +
    ", COALESCE(STDDEV(tenant_records.free_rent_total), 0) AS tile_free_rent " +
    ", COALESCE(STDDEV(tenant_records.escalation), 0) AS tile_escalation " +

    # For Market Effective
    ", COALESCE(SUM((tenant_records.data->'tenant_effective_per_annum')::decimal)::decimal / SUM(tenant_records.size)::decimal, 0) as avg_weighted_market_effective " +
    # For Cushman Market Effective
    ", COALESCE(SUM((tenant_records.cushman_net_effective_per_sf * tenant_records.size)::decimal)::decimal / SUM(tenant_records.size)::decimal, 0) as avg_cushman_market_effective " +
    ", 'summary' as in_scope "
  )
  }

  scope :lease_term_overlap, lambda { |start,finish|
    #having("(tenant_records.lease_commencement_date, tenant_records.lease_commencement_date + (tenant_records.lease_term_months || ' month')::INTERVAL) OVERLAPS (DATE ?, DATE ?)", start, finish)
    having("(tenant_records.lease_commencement_date, DATE_TRUNC('MONTH', tenant_records.lease_commencement_date) + INTERVAL '1 MONTH - 1 DAY') OVERLAPS (DATE ?, DATE ?)", start, finish)
    .group('tenant_records.id')
  }

  def data
    super.with_indifferent_access
  end

  def process_stepped_rents
    processed_rents = []
    unless stepped_rents.empty?
      if stepped_rents.first.cost_per_month.present? && stepped_rents.first.months.present?
        stepped_rents.sort.each do |step|
          processed_rents.concat(Array.new(step.months){ |index| step.cost_per_month / 12.0 })
        end
      end
    end
    missing_length = ((processed_rents.length/12.0).ceil * 12) - processed_rents.length
    processed_rents.concat(Array.new(missing_length){ |index| processed_rents.last })
    processed_rents
  end

  def escalation_type_fixed?
    rent_escalation_type == 'base_rent_fixed_increase' ? true : false
  end

  def first_year_stepped_rents
    stepped_rents = process_stepped_rents
    return nil if stepped_rents.empty?
    stepped_rents.first(12).sum
  end

  def protected?
    #view_type == 'confidential' || view_type == 'network'
    view_type == 'network'
  end

  def public?
    view_type == 'public'
  end

  def confidential?
    view_type == 'confidential'
  end

  def private?
    view_type == 'private'
  end

  def lease_year
    lease_commencement_date.year if ! lease_commencement_date.nil?
  end

  def protect_record
    if (self.respond_to?('in_scope'))
      if (self.in_scope == 'six_sigma')
        two_tile   = self.the_avg.to_f - (2 * self.the_tile.to_f)
        three_tile = self.the_avg.to_f - (1 * self.the_tile.to_f)
        four_tile  = self.the_avg.to_f
        five_tile  = self.the_avg.to_f + (1 * self.the_tile.to_f)
          the_value = self.read_attribute(self.the_field)
        if ( the_value <= two_tile )
          self.selected_six_sigma = "one"
        elsif ( the_value <= three_tile )
          self.selected_six_sigma = "two"
        elsif ( the_value <= four_tile )
          self.selected_six_sigma = "four"
        elsif ( the_value <= five_tile )
          self.selected_six_sigma = "five"
        end
      end


      if (self.in_scope == 'protect_view')
        if  (self.has_attribute? :user_scope and (self.user_scope == 'admin' or self.user_scope == 'analyst') ) ||
            (self.has_attribute? :in_scope_team_ids and self.in_scope_team_ids.split(',').include?(self.team_id.to_s))
          self.view_type = 'public'
          # records are editable to team members who aren't brokers
          self.editable = (self.has_attribute? :user_scope and self.user_scope == 'broker') ? 0 : 1
        else
          # why is the 0 in the query converted to a string? WTH?
          self.editable = 0
        end

       if self.view_type == 'private'
          self.address1                                  = "PRIVATE"
          self.suite                                     = 'private'
          self.city                                      = 'private'
          self.state                                     = 'private'
          self.zipcode                                   = 'private'
          self.size                                      = 'private'
          self.base_rent                                 = 'private'
          self.comments                                  = 'private'
          self.escalation                                = 'private'
          self.free_rent_total                           = 'private'
          self.free_rent                                 = 'private'
          self.lease_expiration_date                     = 'private'
          self.lease_commencement_date                   = 'private'
          self.lease_structure                           = 'private'
          self.lease_term_months                         = 'private'
          self.lease_type                                = 'private'
          self.location_type                             = 'private'
          self.net_effective_per_sf                      = 'private'
          self.tenant_improvement                        = 'private'
          self.tenant_ti_cost                            = 'private'
          self.company                                   = ''
          #self.industry_sic_code_id                      = 'private'
          self.industry_type                             = 'private'
        elsif self.view_type == 'confidential'
          self.base_rent                                 = 'confidential'
          self.comments                                  = 'confidential'
          self.escalation                                = 'confidential'
          self.free_rent_total                           = 'confidential'
          self.free_rent                                 = 'confidential'
          self.lease_expiration_date                     = 'confidential'
          self.lease_commencement_date                   = DateTime.new(self.lease_commencement_date.year,12,31) # Only need year, the month/day doesn't matter
          self.lease_structure                           = 'confidential'
          self.lease_term_months                         = 'confidential'
          self.lease_type                                = 'confidential'
          self.location_type                             = 'confidential'
          self.net_effective_per_sf                      = 'confidential'
          self.tenant_improvement                        = 'confidential'
          self.tenant_ti_cost                            = 'confidential'
          self.company                                   = 'confidential'
          #self.industry_sic_code_id                      = 'confidential'
          self.industry_type                      = 'confidential'
        elsif self.view_type != 'public'
          self.view_type                                 = view_type
          self.base_rent                                 = view_type
          self.comments                                  = view_type
          self.escalation                                = view_type
          self.free_rent_total                           = view_type
          self.free_rent                                 = view_type
          self.lease_expiration_date                     = view_type
          self.lease_commencement_date                   = view_type
          self.lease_structure                           = view_type
          self.lease_term_months                         = view_type
          self.lease_type                                = view_type
          self.location_type                             = view_type
          self.net_effective_per_sf                      = view_type
          self.tenant_improvement                        = view_type
          self.tenant_ti_cost                            = view_type
          self.company                                   = view_type
          #self.industry_sic_code_id                      = view_type
          self.industry_type                      = view_type
        end
        # Anything that isn't part of the users office is a network
        if self.view_type != 'private' && self.respond_to?('in_scope_office_id') && !self.in_scope_office_id.nil? && self.in_scope_office_id.to_i != self.office_id
          self.view_type                                 = 'network'
          self.base_rent                                 = 'network'
          self.comments                                  = 'network'
          self.escalation                                = 'network'
          self.free_rent_total                           = 'network'
          self.free_rent                                 = 'network'
          self.lease_expiration_date                     = 'network'
          self.lease_commencement_date                   = DateTime.new(self.lease_commencement_date.year,12,31) # Only need year, the month/day doesn't matter
          self.lease_structure                           = 'network'
          self.lease_term_months                         = 'network'
          self.lease_type                                = 'network'
          self.location_type                             = 'network'
          self.net_effective_per_sf                      = 'network'
          self.tenant_improvement                        = 'network'
          self.tenant_ti_cost                            = 'network'
          self.company                                   = 'network'
          #self.industry_sic_code_id                      = 'network'
          self.industry_type                      = 'network'
        end
      end
    end
  end

  ## legacy
  def lease_structure
    (self.attributes["lease_structure"] || self[:data]["leasestructure_name"]).split('_').map(&:capitalize).join(' ')
  end

  def lease_structure_id
    LeaseStructure.where( ["lower(name) = ?", lease_structure.downcase]).first.id rescue nil
  end

  def lease_structure=(v)
    self[:data]["leasestructure_name"] = v.to_s
  end

  def lease_structure_description
    self[:data]["leasestructure_description"]
  end

  def lease_structure_description=(v)
    self[:data]["leasestructure_description"] = v.to_s
  end

  def discount_rate
    self[:data]["leasestructure_discount_rate"]
  end

  def discount_rate=(v)
    self[:data]["leasestructure_discount_rate"] = v.to_s
  end

  def interest_rate
    self[:data]["leasestructure_interest_rate"]
  end

  def interest_rate=(v)
    self[:data]["leasestructure_interest_rate"] = v.to_s
  end

  def set_custom_allowance_attributes(custom_allowance_attributes)
    custom_allowance_attributes.each do |key, value|
      self[:data]["#{key}"] = value
    end
  end

  def set_lease_structure(ls)
    self.lease_structure = ls.name
    self.lease_structure_description = ls.description
    self.discount_rate = ls.discount_rate
    self.interest_rate = ls.interest_rate

    self.destroy_keys :data, *self[:data].keys.grep(/^leasestructure_expenses_/)
    ls.expenses.each do |e|
      exp_name = "leasestructure_expenses_#{e.name.parameterize('_')}"
      self[:data]["#{exp_name}_cost"] = e.default_cost
      self[:data]["#{exp_name}_calc_type"] = e.calculation_type
      self[:data]["#{exp_name}_increase_percent"] = e.increase_percent
      self[:data]["#{exp_name}_start_date"] = e.start_date
      self[:data]["#{exp_name}_delay_start_date"] = e.delay_start_date
    end

  end

  def expenses
    regex = /^leasestructure_expenses_(\w+)_cost$/
    expenses = self[:data].keys.grep(regex) do |key|
      name = key.match(regex)[1]
      data = {
        name: name.humanize,
        cost: self[:data][key],
        calculation_type: self[:data]["leasestructure_expenses_#{name}_calc_type"],
        increase_percent: self[:data]["leasestructure_expenses_#{name}_increase_percent"],
      }
      data = data.merge({start_date: self[:data]["leasestructure_expenses_#{name}_start_date"]}) if self[:data].has_key? "leasestructure_expenses_#{name}_start_date"
      data = data.merge({delay_start_date: self[:data]["leasestructure_expenses_#{name}_delay_start_date"]}) if self[:data].has_key? "leasestructure_expenses_#{name}_delay_start_date"
      [name, data]
    end
    Hash[expenses]
  end

  def expenses=(v)
    self.destroy_keys :data, *self[:data].keys.grep(/^leasestructure_expenses_/)
    v.each_pair do |k,expense|
      self[:data]["leasestructure_expenses_#{k.to_s.parameterize('_')}_cost"] = expense[:cost].to_s
      self[:data]["leasestructure_expenses_#{k.to_s.parameterize('_')}_calc_type"] = expense[:calculation_type].to_s
      self[:data]["leasestructure_expenses_#{k.to_s.parameterize('_')}_increase_percent"] = expense[:increase_percent].to_s
      self[:data]["leasestructure_expenses_#{k.to_s.parameterize('_')}_start_date"] = expense[:start_date].to_s if expense.has_key? :start_date and expense[:calculation_type].to_s == "with_start_and_base_year"
      self[:data]["leasestructure_expenses_#{k.to_s.parameterize('_')}_delay_start_date"] = expense[:delay_start_date].to_s if expense.has_key? :delay_start_date
    end
  end

  def base_rent
    first_year_stepped_rents || self[:data]["first_year_base_rent"]
  end

  def base_rent=(v)
    self[:base_rent] = v
    self[:data]["first_year_base_rent"] = v.to_s
  end

  def lease_term_years
    lease_term_months / 12 if lease_term_months
  end

  def lease_expiration_date=(v)
    self.lease_term_months = (v.year * 12 + v.month) - (lease_commencement_date.year * 12 + lease_commencement_date.month) if v.is_a? Date
    v
  end

  def lease_expiration_date
    ( (lease_commencement_date + lease_term_months.months) - 1.month).end_of_month if lease_commencement_date.is_a? Date and lease_term_months
  end

  def custom=(v)
    custom = {}
    if v.is_a? Array or v.is_a? HashWithIndifferentAccess or v.is_a? Hash
      v.values.collect { |x| custom[x["key"].gsub(/\ /, "_").gsub("\n","_").downcase.to_sym] = x["value"] }
      custom = custom.to_json
    elsif v.is_a? String
      custom = v.gsub(/\\\"/, "\"").gsub(/^\"/, "").gsub(/\"$/,"").gsub(/=>/, ':').to_s
    else
      custom = v
    end
    self[:data]['custom'] = custom
  end

  def custom
    JSON.parse(self[:data]['custom']) if self[:data]['custom']
  end

  def method_missing(method_name, *args)
    str_method = method_name.to_s

    #if str_method.match /^leasestructure_expenses_(\w+)_(cost|calc_type|increase_percent|start_date)=?$/
    if str_method.match /^leasestructure_(expenses_)?(\w+)?(_)?(cost|calc_type|increase_percent|start_date|name|description|discount_rate|interest_rate)=?$/
      if str_method.end_with?("=") and args.length >= 1
        self[:data][str_method.chomp("=")] = args[0].to_s
      else
        self[:data][str_method]
      end
    else
      super
    end
  end

  def property_group(section)
    case section
    when "record_ownership" then [:team, :contact, :contact_email, :contact_phone, :comp_type, :view_type]
    #when "record_details" then [:company, :address1, :suite, :city, :state, :zipcode, :zipcode_plus, :location_type, :industry_sic_code_id]
    when "record_details" then [:company, :address1, :suite, :city, :state, :zipcode, :zipcode_plus, :location_type, :industry_type]
    when "property_information" then [:comments, :class_type, :property_type] #:main_image
    when "lease_details" then [:size, :free_rent, :lease_commencement_date, :lease_term_months, :tenant_improvement, :tenant_ti_cost, :lease_type]
    when "rents" then
      if self.stepped_rents.any?
        [:stepped_rents, :stepped_rents_equal_term_months]
      else
        [:base_rent, :escalation]
      end
    else
      false
    end
  end

  def calculate
    RunTenantEffectiveCalculatorWorker.perform_async(self.id)
  end

  def stepped_rents_equal_term_months
    if stepped_rents.any?
      step_months = stepped_rents.reduce(0) { |sum,n| sum + n.months.to_i }
      if step_months != lease_term_months
        errors.add(:stepped_rents, "must equal the number of lease terms")
      end
    end
  end

  ## override dup to create deep copy
  def dup
    d = super
    d.stepped_rents = stepped_rents.dup
    d
  end



  private
  def default_values
    self.address1 = self.address1.to_s.strip
    self.base_rent ||= 0.00
    self.class_type = class_type.to_s.downcase
    self.comp_type = comp_type.to_s.downcase
    self.comp_type ||= 'internal'
    self.escalation ||= 0.00

    self.lease_type = lease_type.to_s.strip.presence || '-'

    # Need to set default first_year_base_rent to base rent
    self.data ||= (first_year_stepped_rent || Hash['first_year_base_rent', self.base_rent])

    self.property_type = property_type.to_s.downcase
    self.tenant_improvement ||= 0.00
    self.view_type = view_type.to_s.downcase
    case self.view_type
    when 'transparent'
      self.view_type = 'public'
    else
      # allow the validation to make it fail
    end

    # set proper ordering on any associated stepped rents
    self.stepped_rents.each_with_index { |rent, idx| rent.order = idx }

    # this true keeps validation from failing...
    true
  end

  def add_to_all_office_agreements
    return if office_id.nil? or office.nil?
    Office.find(office_id).agreements.each { |agreement|
      agreement.tenant_records << self
      agreement.save
    }
  end

  def remove_from_all_office_agreements
    return if office_id.nil? or office.nil?
    Office.find(office_id).agreements.each { |agreement|
      agreement.tenant_records.destroy(self)
      agreement.save
    }
  end

  def do_net_effective_calculator
    begin
      RunTenantEffectiveCalculatorWorker.perform_in(15.seconds, self.id) if self.base_rent.to_f > 0 || !stepped_rents.blank?
    rescue Exception => e
      logger.error e.inspect + "\n" + e.message + "\n" + e.backtrace.join("\n")
    end
  end

  def populate_lookup_tables
    if self.address1_changed? or self.zipcode_changed? or self.latitude_changed? or self.longitude_changed?
      o = LookupAddressZipcode.find_by_name([self.address1_was, self.zipcode_was].join(', '));
      if !o.nil?
        o.tenant_records.destroy(self)
        o.save
      end
      l = LookupAddressZipcode.find_or_create_by_name(name: [self.address1, self.zipcode].join(', '))
      l.city = self.city if self.city
      l.state = self.state if self.state
      l.set_latlon(self.latitude, self.longitude) if self.latitude and self.longitude
      l.tenant_records << self
      l.save
    end
    if self.company_changed?
      o = LookupCompany.find_by_name(self.company_was)
      if !o.nil?
        o.tenant_records.destroy(self)
        o.save
      end
      l = LookupCompany.find_or_create_by_name(name: self.company)
      l.tenant_records << self
      l.save
    end
    if self.submarket_changed?
      o = LookupSubmarket.find_by_name(self.submarket_was)
      if !o.nil?
        o.tenant_records.destroy(self)
        o.save
      end
      l = LookupSubmarket.find_or_create_by_name(name: self.submarket)
      l.tenant_records << self
      l.save
    end
    if self.property_name_changed?
      o = LookupPropertyName.find_by_name(self.property_name_was)
      if !o.nil?
        o.tenant_records.destroy(self)
        o.save
      end
      l = LookupPropertyName.find_or_create_by_name(name: self.property_name)
      l.tenant_records << self
      l.save
    end
  end
end
