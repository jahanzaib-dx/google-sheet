include ActionView::Helpers::NumberHelper
include Finance

module CushmanCalculationEngine

  # driver code: setup input parameters for cushman_calculations method
  def retrieve_cushman_metrics(tenant_record)
    final_result = []
    if tenant_record.stepped_rents.present?
      free_rent_months = get_free_months(tenant_record.free_rent.to_s)
      discount_rate = tenant_record.leasestructure_discount_rate.to_f
      work_allowance = tenant_record.tenant_improvement
      step_up_rents = []

      tenant_record.stepped_rents.each do |step|
        current_step = []
        current_step << step.cost_per_month << (step.months.to_f / 12.to_f)
        step_up_rents << current_step
      end
      final_result = cushman_calculations(tenant_record, free_rent_months, work_allowance, step_up_rents, discount_rate)
    end
    final_result
  end

  def cushman_calculations(tenant_record, free_rent_months, work_allowance, step_up_rents, discount_rate)
    # 1. calculate length_of_terms in months and years
    length_of_terms_months = 0
    duration = 0

    step_up_rents.each do |rent|
      duration += (rent[1] * 12)
    end
    length_of_terms_months = duration.round
    length_of_terms_years = "#{(length_of_terms_months / 12)} Years & #{(length_of_terms_months % 12)} Months"

    total_rent_months = (1..length_of_terms_months + free_rent_months).to_a

    # 2. calculate NPV including free rent
    cal_units = calculate_monthly_units(free_rent_months, total_rent_months, step_up_rents)
    npv_rate = ((discount_rate / 100) / 12)
    npv = cal_units.npv(npv_rate)

    # 3. calculate PMT
    denominator = (npv_rate == 0 ? length_of_terms_months.to_f : (((1 - ((1 + npv_rate) ** -length_of_terms_months)) / npv_rate) * (1 + npv_rate)))

    pmt = (npv / denominator)

    # 4. calculate effective rent
    effective_rent = pmt * 12

    # 5. calculate effective ti
    effective_ti = (((work_allowance / denominator) * 12) * -1)

    # 6. calculate net effective rent
    net_effective_rent = effective_rent + effective_ti

    { id: tenant_record.id, length_of_terms_months: "#{length_of_terms_months} Months", length_of_terms_years: length_of_terms_years,
      npv: npv, pmt: pmt, effective_rent: effective_rent, effective_ti: effective_ti, net_effective_rent: net_effective_rent }
  end

  # calculate monthly units for 'NPV' on the basis of defined stepped rents
  def calculate_monthly_units(free_rent_months, total_rent_months, step_up_rents)
    calculated_units = []
    total_rent_months.each do |month|
      result = 0
      if free_rent_months < month
        i = 0
        is_present = false
        while i < step_up_rents.count && !is_present  do
          step = step_up_rents[i]
          step_months_sum ||= step[1]
          if (step_months_sum * 12) >= month
            result = step[0] / 12
            is_present = true
          end
          step_months_sum += step_up_rents[i + 1][1] if !is_present and step_up_rents[i + 1].present?
          i += 1
        end
      end
      calculated_units << result
    end
    calculated_units
  end

  #  calculate CUSHMAN MARKET EFFECTIVE (PER SF/YR)
  def calculate_cushman_market_effective(comp_details)
    net_effect_rent = sf = 0
    comp_details.each do |comp|
      net_effect_rent += (TenantRecord.find(comp.id).cushman_net_effective_per_sf * comp.size)
      sf += comp.size
    end
    (net_effect_rent / sf) rescue 0
  end

  # process free_rent in '1-4,14,16' format and return total free rent months
  def get_free_months(free_rent_range)
    final_result = []
    comma_split = free_rent_range.split(',')
    comma_split.each do |element|
      dash_split = element.split('-')
      if dash_split.length > 1
        (dash_split[0]..dash_split[1]).to_a.each do |val|
          final_result << val
        end
      else
        final_result << element
      end
    end
    ((final_result.length == 1) ? final_result[0].to_i : final_result.length)
  end
end