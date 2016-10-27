# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

def validate_address (office)
  geos = SmartyGeocoder::smarty_streets_geocoder_address({
                                                             :address1 => office.address1,
                                                             :address2 => office.address2,
                                                             :city => office.city,
                                                             :state => office.state,
                                                             :zipcode => office.zipcode,
                                                         })
  unless SmartyGeocoder::valid_address(geos)
    #add errors
    if geos.blank?
      { valid: false, errors: { geocode_info: "There was an error with this address. Please check the address fields and submit again" }}
    else
      { valid: false, errors: SmartyGeocoder::add_smarty_notifications(office,geos) }
    end
  else
    valid = { valid: true, errors: {} }
    geo = geos.first
    valid[:updates] = {
        address1: geo["components"]["delivery_line_1"],
        city: geo["components"]["city_name"],
        state: geo["components"]["state_abbreviation"],
        zipcode: geo["components"]["zipcode"],
        zipcode_plus: geo["components"]["zipcode_plus"],
        latitude: geo["metadata"]["latitude"],
        longitude: geo["metadata"]["longitude"] } if geo.present?
    valid
  end

end

def office_geocode office
  v = validate_address(office)
  if v.has_key? :coords
    office.latitude = v[:coords][:latitude]
    office.longitude = v[:coords][:longitude]
  elsif v.has_key? :errors and v[:errors].has_key? "geocode_info" and v[:errors]["geocode_info"].include? "Better address exists"
    office.latitude = v[:errors]["geocode_addresses"][0]["latitude"]
    office.longitude = v[:errors]["geocode_addresses"][0]["longitude"]
  elsif v.has_key? :updates
    office.latitude = v[:updates][:latitude]
    office.longitude = v[:updates][:longitude]
  end
  office
end

puts "Default Account: admin@tenantrex.com"
 u = User.create(:email=>'admin@tenantrex.com', :password=>'abc123!', :password_confirmation=>'abc123!')
 Account.create(:fullname=>'Administrator', :role=>'trex_admin', :accepted_terms_of_service=>true, :user_id => u.id)

puts "Default Firm"
 f = Firm.create(:name => 'TenantRex Default', :contact_name=>'Adrian Hessen', :contact_phone=>'410-000-0000', :contact_email=>'ahessen@tenantrex.com')

puts "Default Office"
o = Office.create(:name => 'TenantRex Office', :contact_name=>'Adrian Hessen', :contact_phone=>'410-000-0000', :contact_email=>'ahessen@tenantrex.com', :address1 => '902 Broadway', :city => 'New York', :state=>'NY', :zipcode=>10010, :firm_id => f.id)
#  o.agreements.build(:name => o.firm.name + ' ' + o.name + ' Tenant Records',
#                     :description => 'Default collection of office tenant records',
#                     :office_default => true )
 o = office_geocode o
 o.save


puts "Lease Structures"
nnn = LeaseStructure.create(:name => "NNN", :description => "Default NNN", :discount_rate=> 4.0)
nnn.lease_structure_expenses << LeaseStructureExpense.new(:name => 'CAM',
                                                          :calculation_type => 'generic',
                                                          :default_cost => 0.50,
                                                          :increase_percent => 2.00,
                                                          :start_date => nil)
nnn.lease_structure_expenses << LeaseStructureExpense.new(:name => 'Janitorial',
                                                          :calculation_type => 'generic',
                                                          :default_cost => 1.00,
                                                          :increase_percent => 2.00,
                                                          :start_date => nil)
nnn.lease_structure_expenses << LeaseStructureExpense.new(:name => 'Real Estate Tax',
                                                          :calculation_type => 'generic',
                                                          :default_cost => 1.50,
                                                          :increase_percent => 2.00,
                                                          :start_date => nil)
nnn.lease_structure_expenses << LeaseStructureExpense.new(:name => 'Utilities',
                                                          :calculation_type => 'generic',
                                                          :default_cost => 3.00,
                                                          :increase_percent => 2.00,
                                                          :start_date => nil)
nnn.lease_structure_expenses << LeaseStructureExpense.new(:name => 'Insurance',
                                                          :calculation_type => 'generic',
                                                          :default_cost => 0.25,
                                                          :increase_percent => 2.00,
                                                          :start_date => nil)

mg = LeaseStructure.create(:name => "Modified Gross", :description => "Default Modified Gross", :discount_rate=> 4.0)
mg.lease_structure_expenses << LeaseStructureExpense.new(:name => 'Utilities',
                                                         :calculation_type => 'generic',
                                                         :default_cost => 3.00,
                                                         :increase_percent => 2.00,
                                                         :start_date => nil)
mg.lease_structure_expenses << LeaseStructureExpense.new(:name => 'Operating Expense',
                                                         :calculation_type => 'with_start_and_base_year',
                                                         :default_cost => 10.00,
                                                         :increase_percent => 2.00,
                                                         :start_date => nil)

fs = LeaseStructure.create(:name => "Full Service", :description => "Full Service", :discount_rate=> 4.0)
fs.lease_structure_expenses << LeaseStructureExpense.new(:name => 'Operating Expense',
                                                         :calculation_type => 'with_start_and_base_year',
                                                         :default_cost => 10.00,
                                                         :increase_percent => 2.00,
                                                         :start_date => nil)


CATEGORY = ["Record Ownership", "Record Details", "Property Information", "Lease Details", "Rents", "Output metrics", "Custom Fields"]

CATEGORY.each_with_index do |cat, index|
  cat_result = TenantRecordCategory.new(name: cat)
  if cat_result.save
    case index
      when 0
        subcat_object = [["Name", "contact"], ["Email Address", "contact_email"], ["Phone", "contact_phone"], ["Team/Owner", "team_id"], ["Comp Type", "comp_type"], ["Record Visibility", "view_type"]]
      when 1
        subcat_object = [["Company", "company"], ["Address Line 1", "address1"], ["Address Line 2", "suite"], ["City", "city"], ["State", "state"], ["Zipcode", "zipcode"], ["Zip 4", "zipcode_plus"], ["Location Type", "location_type"], ["Industry Type", "industry_type"], ["Property Name", "property_name"], ["Submarket", "submarket"]]
      when 2
        subcat_object = [["Property Type", "property_type"], ["Class Type", "class_type"], ["Comments", "comments"]]
      when 3
        subcat_object = [["Size", "size"], ["Month(s) free rent occurs", "free_rent"], ["Lease Term Months", "lease_term_months"], ["Tenant Improvement", "tenant_improvement"], ["Tenant TI Cost", "tenant_ti_cost"], ["Lease Type", "lease_type"]]
      when 4
        subcat_object = [["Base Rent", "base_rent"], ["Escalation", "escalation"], ["Rent Cost Per SF", "cost_per_month"], ["# Months of Rent", "months"]]
      when 5
        subcat_object = [["Total Rent", "total_rent"], ["Present Value of Total Rent", "present_value_of_total_rent"], ["Average Annual Rent", "average_annual_rent"], ["Tenant Effective Per Annum", "tenant_effective_per_annum"], ["Average per Annum by SF", "average_per_annum_by_sf"], ["Tenant Effective Rent", "tenant_effective_rent"], ["Tenant Expenses by SF", "tenant_expenses_by_sf"], ["Average Base Rent per Annum by SF", "avg_base_rent_per_annum_by_sf"], ["Total Tenant Improvements", "total_tenant_improvements"], ["Amortized Value of TI $/SF", "amortized_value_of_ti_$/sf"], ["Total Value of Free Rent", "total_value_free_rent"], ["Present Value of Free Rent per Annum", "pv_free_rent_per_annum"], ["Present Value Free Rent $/SF per Annum", "pv_free_rent_$/sf_per_annum"], ["Total Concession per Annum", "total_concessions_per_annum"], ["Total LL Income", "total_ll_income"], ["Present Value of LL Income", "present_value_of_ll_income"], ["Landlord Effective Per Annum", "landlord_effective_per_annum"], ["Landlord Effective Rent", "landlord_effective_rent"], ["Landlord Margin", "landlord_margin"], ["Cushman Effect Rent", "cushman_net_effective_per_sf"]]
      when 6
        subcat_object = []
    end
    subcat_object.each do |obj|
      cat_result.tenant_record_category_fields.create(label_name: obj[0], tenant_record_field: obj[1])
    end
  end
end



# marketrex data

industries = [
    'Accommodations',
    'Accounting',
    'Advertising',
    'Aerospace',
    'Agriculture & Agribusiness',
    'Air Transportation',
    'Apparel & Accessories',
    'Auto',
    'Banking',
    'Beauty & Cosmetics',
    'Biotechnology',
    'Chemical',
    'Communications',
    'Computer',
    'Construction',
    'Consulting',
    'Consumer Products',
    'Education',
    'Electronics',
    'Employment',
    'Energy',
    'Entertainment & Recreation',
    'Fashion',
    'Financial Services',
    'Food & Beverage',
    'Health',
    'Information',
    'Information Technology',
    'Insurance',
    'Journalism & News',
    'Legal Services',
    'Manufacturing',
    'Media & Broadcasting',
    'Medical Devices & Supplies',
    'Motion Pictures & Video',
    'Music',
    'Pharmaceutical',
    'Public Administration',
    'Public Relations',
    'Publishing',
    'Real Estate',
    'Retail',
    'Service',
    'Sports',
    'Technology',
    'Telecommunications',
    'Tourism',
    'Transportation',
    'Travel',
    'Utilities',
    'Video Game',
    'Web Services'
]



industries.each do |industry|
  Industry.create(name: industry)
end



MarketExpense.delete_all
OpexMarket.delete_all
PropertyType.delete_all

puts "MarketExpense, OpexMarket & PropertyType Table entries removed  ..."

def convert(key)
  updated_key = if key == "Roads / Grounds" || key == "Grounds/Landscape"
                  "Grounds/Landscape".downcase.gsub(" ", "").gsub("/", "_")
                else
                  (key == 'Payroll & Benefits') ?
                      "payroll_and_benefits" : key.downcase.gsub(" ", "_").gsub("/", "_")
                end

  updated_key
end

require 'roo'

property_type = ["Office", "Industrial", "Retail"]
spreadsheet = Roo::Excelx.new('./db/markets.xlsx')

property_type.each do |pt|
  @property_type = PropertyType.create(name: pt)
  header = spreadsheet.sheet(pt).row(1)

  puts "Process started ..."
  (2..spreadsheet.last_row).each do |i|
    row = Hash[[header, spreadsheet.row(i)].transpose]

    market_attributes = row.to_hash.slice("Name", "Code")

    if pt == 'Office'
      expenses_attributes = row.to_hash.slice("Taxes", "Insurance", "Utilities",
                                              "CAM", "Janitorial", "Administrative", "Roads / Grounds",
                                              "Security", "Other Tax", "Total Opex")
    elsif pt == 'Industrial'
      expenses_attributes = row.to_hash.slice("Taxes", "Insurance", "Utilities",
                                              "CAM", "Janitorial","Payroll & Benefits", "Management Fee",
                                              "Administrative", "Grounds/Landscape", "Total Opex")

    else
      expenses_attributes = row.to_hash.slice("Taxes", "Insurance", "Utilities",
                                              "CAM", "Janitorial","Payroll & Benefits", "Management Fee",
                                              "Administrative", "Total Opex")
    end

    market_hash = {}
    market_attributes.to_hash.each_pair do |k,v|
      market_hash.merge!({ k.downcase.gsub(" ", "") => v })
    end

    market_expenses_hash = {}
    expenses_attributes.to_hash.each_pair do |k,v|
      key = convert(k)
      market_expenses_hash.merge!({ key => v })
    end
    @opex = @property_type.opex_markets.new(market_hash)
    if @opex.save
      @opex.market_expense = MarketExpense.create(market_expenses_hash)
    end
  end
end
puts "Process completed ..."

