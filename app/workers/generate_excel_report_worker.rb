class GenerateExcelReportWorker
  include Sidekiq::Worker
  include SearchControllerUtil
  include CalculatorUtil
  include ActionView::Helpers::NumberHelper

  sidekiq_options :queue => :xls

  # process all the names we had used prior
  def utilities(expenses)
    if expenses["utilities"].presence
      expenses["utilities"][:cost]
    elsif expenses["electrical_expense"].presence
      expenses["electrical_expense"][:cost]
    elsif expenses["electric"].presence
      expenses["electric"][:cost]
    else
      nil
    end
  end

  # get Field Names and Values separately
  def parse_custom_fields(custom_fields)
    if custom_fields.present?
      combined_keys = combined_values =  []
      custom_fields.each_with_index do |(key, value), index|
        combined_keys << (key.present? ? key.to_s : '-')
        combined_values << (value.present? ? value.to_s : '-')
      end
      "Fields: #{combined_keys.join(', ')} Values: #{combined_values.join(', ')}"
    end
  end

  # calculate output_metrics
  def calculate_export_summary(id)
    @tenant_record = TenantRecord.find(id)
    #if user isn't at least an analyst and the record is public, they can see it.
    @results = calculate(@tenant_record) unless  @tenant_record.view_type != 'public' #and cannot?(:update, @tenant_record)
    @results
  end

  def perform(path, criteria, user_id)
    user = User.find(user_id)
    export_fields = criteria['export_field']
    criteria['tenant_record']['address1'] = criteria['address1']
    criteria['tenant_record']['zipcode'] = criteria['zipcode']
    criteria['tenant_record']['q'] = criteria['q']
    criteria = criteria['tenant_record']

    # get tenant records
    summary = scope_records_by_params(criteria.merge!({'summary' => true}), user).all.first

    # get tenant summary
    # if criteria.include?('disable_view_type')
    #   criteria['disable_view_type'] = criteria['disable_view_type'].push('private').uniq
    # else
    #   criteria['disable_view_type'] = ['private']
    # end
    all = scope_records_by_params(criteria.merge!({'summary' => false}), user)

    records = Array.new
    records << ["Address", "Company", "Size", "Tenant Effective Per SF", "Lease Year"]

    panels = {"one" => 1, "two" => 2, "three" => 3, "four" => 4, "five" => 5, "six" => 6}
    points = [
      (1*summary.avg_net_effective_per_sf.to_f) - (3*summary.tile_net_effective_per_sf.to_f),
      (1*summary.avg_net_effective_per_sf.to_f) - (2*summary.tile_net_effective_per_sf.to_f),
      (1*summary.avg_net_effective_per_sf.to_f) - (1*summary.tile_net_effective_per_sf.to_f),
      summary.avg_net_effective_per_sf.to_f.to_s,
      (1*summary.avg_net_effective_per_sf.to_f) + (1*summary.tile_net_effective_per_sf.to_f),
      (1*summary.avg_net_effective_per_sf.to_f) + (2*summary.tile_net_effective_per_sf.to_f),
      (1*summary.avg_net_effective_per_sf.to_f) + (3*summary.tile_net_effective_per_sf.to_f)
    ]

    book = WriteExcel.new path
    sheet = book.add_worksheet

    columns = {
      # lease_structure attributes
      lease_structure: 'Lease Structure Name',
      lease_structure_description: 'Description',
      leasestructure_discount_rate: 'Discount %',
      leasestructure_interest_rate: 'Interest Rate %',
      # lease_structure_expenses attributes
      cam: "Cam Cost",
      leasestructure_expenses_cam_cost: "Defaults",
      leasestructure_expenses_cam_increase_percent: "Increase %",
      janitorial: "Janitorial",
      leasestructure_expenses_janitorial_cost: "Defaults",
      leasestructure_expenses_janitorial_increase_percent: "Increase %",
      real_estate_tax: "Taxes",
      leasestructure_expenses_real_estate_tax_cost: "Defaults",
      leasestructure_expenses_real_estate_tax_increase_percent: "Increase %",
      utilities: "Utilities",
      leasestructure_expenses_utilities_cost: "Defaults",
      leasestructure_expenses_utilities_increase_percent: "Increase %",
      insurance: "Insurance Expenses",
      leasestructure_expenses_insurance_cost: "Defaults",
      leasestructure_expenses_insurance_increase_percent: "Increase %",
      operating_expense: "Operating Expenses",
      leasestructure_expenses_operating_expense_cost: "Defaults",
      leasestructure_expenses_operating_expense_increase_percent: "Increase %",
      # record_ownership attributes
      contact: 'Contact Name',
      contact_email: 'Email Adress',
      contact_phone: 'Phone',
      team_id: 'Team/Owner',
      comp_type: 'Comp Type',
      view_type: 'Record Visibility',
      # record_details attributes
      company: 'Company',
      address1: 'Address Line 1',
      suite: 'Address Line 2',
      city: 'City',
      state: 'State',
      zipcode: 'Zipcode',
      zipcode_plus: 'Zip 4',
      location_type: 'Location Type',
      industry_type: 'Industry Type',
      property_name: 'Property Name',
      submarket: 'Submarket',
      # property_information attributes
      property_type: 'Property Type',
      class_type: 'Class Type',
      comments: 'Comments',
      # lease_details attributes
      size: 'Tenant Size',
      free_rent: 'Free Rent (Months)',
      lease_commencement_date: 'Lease Commencement Date',
      lease_term_months: 'Lease Term Months',
      tenant_improvement: 'Tenant Improvement (Per SF)',
      tenant_ti_cost: 'Tenant TI (Per SF)',
      lease_type: 'Lease Type',
      # rents attributes
      base_rent: 'Base Rent',
      escalation: 'Escalation',
      cost_per_month: 'Rent Cost Per SF',
      months: '# Months Rent',
    }
    output_metrics = {
        total_rent: 'Total Rent',
        present_value_of_total_rent: 'Present Value of Total Rent',
        average_annual_rent: 'Average Annual Rent',
        tenant_effective_per_annum: 'Tenant Effective per Annum',
        average_per_annum_by_sf: 'Average per Annum by SF',
        tenant_effective_rent: 'Tenant Effective Rent',
        cushman_net_effective_per_sf: 'Cushman Effective Rent',
        tenant_expenses_by_sf: 'Tenant Expenses by SF',
        avg_base_rent_per_annum_by_sf: 'Average Base Rent per Annum by SF',
        total_tenant_improvements: 'Total Tenant Improvements',
        'amortized_value_of_ti_$/sf' => 'Amortized Value of Ti $/Sf',
        total_value_free_rent: 'Total Value Free Rent',
        pv_of_free_rent: 'Present Value of Free Rent',
        pv_free_rent_per_annum: 'Present Value Free Rent per Annum',
        'pv_free_rent_$/sf_per_annum' => 'Present Value Free Rent $/Sf per Annum',
        total_concessions_per_annum: 'Total Concessions per Annum',
        total_ll_income: 'Total LL Income',
        present_value_of_ll_income: 'Present Value of LL Income',
        landlord_effective_per_annum: 'Landlord Effective per Annum',
        landlord_effective_rent: 'Landlord Effective Rent',
        landlord_margin: 'Landlord Margin',
        fs_equivalent: 'Fs Equivalent'
    }

    custom_column_keys = []
    all.each_with_index do |t, idx|
      if t.custom.present?
        t.custom.each do |custom_fields_key, value|
          columns.merge!("custom_fields*#{custom_fields_key}" => "Custom: #{custom_fields_key.to_s.humanize}")
          custom_column_keys << "custom_fields*#{custom_fields_key}"
        end
      end
    end
    columns.merge!(output_metrics)
    output_metrics.symbolize_keys!

    if export_fields.include?('rent_attributes')
      export_fields << 'base_rent' << 'escalation' << 'cost_per_month' << 'months'
    end

    if export_fields.include?('custom')
      custom_column_keys.each do |key|
        export_fields << key
      end
    end

    # remove any columns which weren't checked off
    if export_fields.present?
      columns.delete_if { |k, v| !export_fields.include? k.to_s }
    end

    sheet.write_row(0, 0, columns.values)
    all.each_with_index do |t, idx|
      @tr_output_metrics = calculate_export_summary(t.id)
      row = Array.new

      if(t.private? || t.confidential?)
        row = columns.keys.collect do |k|
          next '--' unless [:address1].include?(k)
          t.send(k.to_s)
        end
      elsif(t.protected?)
        row = columns.keys.collect do |k|
          next '--' unless [:address1, :company, :size, :net_effective_per_sf, :lease_year].include?(k)

          if k.eql? :net_effective_per_sf
            # calculate six sigma
            selected = get_sixsigma(t.id,'net_effective_per_sf', summary.avg_net_effective_per_sf, summary.tile_net_effective_per_sf).selected_six_sigma
            range_min = points[panels[selected] - 1]
            range_max = points[panels[selected]]
            "#{range_min.to_f.round(2)} - #{range_max.to_f.round(2)}"
          else
            t.send(k.to_s)
          end
        end
      else
        row = columns.keys.collect do |k|
          if output_metrics.include?(k.to_sym) && k != :cushman_net_effective_per_sf
            formatted_val = @tr_output_metrics[:summary][k.to_sym] rescue 0.0
            (k.to_s == 'landlord_margin') ?
                number_to_percentage(formatted_val, { precision: 2 }) : number_to_currency(formatted_val)
          else
            case k
            when :net_effective_per_sf then t.net_effective_per_sf.round(2)
            when :property_type, :location_type then t[k].capitalize! if t[k].present?
            when :lease_commencement_date then t.lease_commencement_date.strftime('%m/%d/%Y')
            when :lease_structure then (t.lease_structure =~ /nnn/i ? t.lease_structure.upcase : t.lease_structure.humanize) if t.lease_structure.present?
            when :real_estate_tax, :operating_expense, :cam, :janitorial, :insurance then (t.expenses[k.to_s].present?) ? t.expenses[k.to_s][:cost] : '--'
            when :utilities then utilities(t.expenses)
            when :team_id then t.team.name if t.team.present?
            when :cost_per_month, :months then t.stepped_rents.pluck(k).join(', ') if t.stepped_rents.any?
            when :cushman_net_effective_per_sf then number_to_currency(t.cushman_net_effective_per_sf)
            else
                if k.to_s.include?('custom_fields')
                  ((t.custom.include? k.to_s.split('*')[1..k.to_s.length].join) ?
                      t.custom[k.to_s.split('*')[1..k.to_s.length].join] : '--') if t.custom.present?
                else
                  t.send(k.to_s)
                end
            end
          end
        end
      end

      sheet.write_row(idx + 1, 0, row)
    end

    book.close
  end
end
