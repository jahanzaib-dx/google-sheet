class MarketExpense < ActiveRecord::Base

  # attr_accessible :taxes, :insurance, :utilities, :cam, :janitorial, :administrative,
  #                 :grounds_landscape, :payroll_and_benefits, :management_fee,
  #                 :security, :other_tax, :total_opex

  belongs_to :opex_market

  # property type attributes; different for office, industrial, retail
  OFFICE_ATTRIBUTES = 'taxes, insurance, utilities, cam, janitorial, administrative, grounds_landscape,
                       security, other_tax, total_opex'

  INDUSTRIAL_ATTRIBUTES = 'taxes, insurance, utilities, cam, janitorial, management_fee, payroll_and_benefits,
                           administrative, grounds_landscape, total_opex'

  RETAIL_ATTRIBUTES = 'taxes, insurance, utilities, cam, janitorial, management_fee, payroll_and_benefits,
                       administrative, total_opex'


  def self.market_expenses_list(opex_market_id)
    result_set = where("opex_market_id = ?", opex_market_id)
    property_type = result_set.first.opex_market.property_type.name

    if property_type.downcase == 'office'
      result_set.select(OFFICE_ATTRIBUTES)
    elsif property_type.downcase == 'industrial'
      result_set.select(INDUSTRIAL_ATTRIBUTES)
    else
      result_set.select(RETAIL_ATTRIBUTES)
    end
  end

  def self.opex_type_list
    ['taxes', 'insurance', 'utilities', 'cam', 'janitorial', 'management_fee',
     'payroll_and_benefits','administrative', 'grounds_landscape',
     'security', 'other_tax', 'total_opex']
  end
end
