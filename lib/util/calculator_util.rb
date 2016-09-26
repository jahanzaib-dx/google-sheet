require 'finance'

module CalculatorUtil

  def calculate(tenant_record = nil, type ='TenantEffective')
    return nil if tenant_record.nil?
    TenantEffective.new(tenant_record).calculate if type == 'TenantEffective'
  end

  def execute(tenant_record = nil, type = 'TenantEffective')
    calculate(tenant_record, type)
  end

  def pull_attributes(results, trec)
    trec_data = trec.data
    # UPDATING TENANT RECORD
    attributes = {
      :net_effective_per_sf => results[:summary]['tenant_effective_rent_($/sf)'.to_sym].to_f,
      :landlord_concessions_per_sf => results[:summary]['total_ll_concessions_$/sf'.to_sym].to_f,
      :landlord_effective_rent => results[:summary]['ll_effective_rent_($/sf)'.to_sym].to_f,
      :landlord_margins => results[:summary][:landlord_margin].to_f,
      :avg_base_rent_per_annum_by_sf => results[:summary]['avg_base_rent_(no_expenses)_$/sf'.to_sym].to_f
    }
    if !trec_data.blank?
      if trec.lease_term_months >= 12
        first_year_base_rent = results[1][:tenant_costs_per_year][:pre_free_rent].to_s
      else
        first_year_base_rent = trec_data[:first_year_base_rent].to_f
      end
      attributes = attributes.merge(:free_rent_total => results[:free_rent_summary][:free_rent_total],
                                    :data => trec_data.merge(Hash[
          'tenant_effective_per_annum', results[:summary]['pv_annual_rent_(average)'.to_sym].to_f,
          'landlord_effective_per_annum', results[:summary]['pv_annual_income_(average)'.to_sym].to_f, 
          'average_annual_rent', results[:summary]['annual_rent_(average)'.to_sym].to_f,
          'first_year_base_rent', first_year_base_rent,
          'fs_equivalent', results[:summary][:fs_equivalent].to_f
        ]))
    end
    attributes
  end

  class TenantEffective

    def initialize(record)
      @commencement        = record.lease_commencement_date
      @term_months         = record.lease_term_months.to_i
      @expiration          = record.lease_expiration_date
      @is_base_rent        = record.stepped_rents.empty?
      @base_rent           = record.base_rent.to_f
      @rents               = @is_base_rent ? Array.new(@term_months) { |index| record.base_rent.to_f / 12.0 } : record.process_stepped_rents
      @rentable_sf         = record.size.to_i
      @rent_escalation_fixed = record.escalation_type_fixed?
      @annual_escalation   = @rent_escalation_fixed ? record.fixed_escalation.to_f : record.escalation.to_f / 100.0
      @discount_rate       = record.discount_rate.to_f / 100.0
      @interest_rate       = record.interest_rate.to_f / 100.0
      @free_rent_interval  = process_free_rent_interval(record.free_rent, record.free_rent_type)
      @tenant_improvements = record.tenant_improvement.to_f
      @tenant_ti           = record.tenant_ti_cost.to_f
      @additional_tenant_cost  = record.additional_tenant_cost.to_f
      @additional_ll_allowance = record.additional_ll_allowance.to_f
      @expenses            = record.expenses
      @gross_free_rent     = record.gross_free_rent
      @results = {}
      @without_delay = {}
      @delay_start_discount = []
      @delay_start_discount_for_term_greater_12 = []
    end

    def calculate
      period = 1
      store  = period
      1.upto(@term_months) do |month|
        store, period = new_bill_period(store, period, month)
        @results[store][:tenant_costs_per_year][:pre_free_rent] = pre_free_rent(store, period, month)
        @results[store][:tenant_costs_per_year][:base_rent_increase], @results[store][:tenant_costs_per_year][:non_prorated_base_rent_increase] = base_rent_increase(store, period, month)
        @results[store][:tenant_costs_per_year][:expenses] ||= {}
        @results[store][:landlord_costs_per_year][:expenses] ||= {}
        @results[store][:landlord_costs_per_year][:landlord_expenses] ||= 0.0

        @without_delay[store][:tenant_costs_per_year][:pre_free_rent] = pre_free_rent(store, period, month)
        @without_delay[store][:tenant_costs_per_year][:base_rent_increase], @results[store][:tenant_costs_per_year][:non_prorated_base_rent_increase] = base_rent_increase(store, period, month)
        @without_delay[store][:tenant_costs_per_year][:expenses] ||= {}
        @without_delay[store][:landlord_costs_per_year][:expenses] ||= {}
        @without_delay[store][:landlord_costs_per_year][:landlord_expenses] ||= 0.0

        @delay_start_discount[month] = 0.0
        @delay_start_discount_for_term_greater_12[month] = 0.0
        @delay_start_discount[month] -= (@tenant_ti * @rentable_sf) if month == 1
        @delay_start_discount[month] -= (@additional_tenant_cost * @rentable_sf) if month == 1
        @expenses.keys.each { |key|
          previous_store_expense_cost2 = total_expense_cost('tenant_costs_per_year', key, period)
          tenant_data2 = tenant_expenses( datatype: key, bill_period: period, month: month, previous_cost_value: previous_store_expense_cost2 )
          landlord_data2 = landlord_expenses( datatype: key, bill_period: period )
          @without_delay[store][:tenant_costs_per_year][key] ||= 0.0
          @without_delay[store][:tenant_costs_per_year][key] += tenant_data2 if tenant_data2
          @without_delay[store][:tenant_costs_per_year][:expenses][key] = (tenant_data2 * 12.0 if tenant_data2) || 0.0
          @without_delay[store][:landlord_costs_per_year][:expenses][key] = (landlord_data2 * -12 if landlord_data2) || 0.0
          @without_delay[store][:landlord_costs_per_year][:landlord_expenses] -= landlord_data2 if landlord_data2

          previous_store_expense_cost = total_expense_cost('tenant_costs_per_year', key, period)
          tenant_data = tenant_expenses( datatype: key, bill_period: period, month: month, previous_cost_value: previous_store_expense_cost )
          if @gross_free_rent
            if @free_rent_interval.include?((month).to_i)
              @delay_start_discount[month] += tenant_data * @rentable_sf
              @delay_start_discount_for_term_greater_12[month] += tenant_data * @rentable_sf
              tenant_data = 0.0
            end
          elsif (@expenses[key][:calculation_type] == 'pass_through_and_start_date')
            delay_start_date = @expenses[key][:delay_start_date].to_date
            commencement_date = @commencement
            delay_start_month = (delay_start_date.year * 12 + delay_start_date.month) - (commencement_date.year * 12 + commencement_date.month)
            if month <= delay_start_month
              if ((month / 12).floor == (delay_start_month / 12).floor) && (month % 12) != 0
                @delay_start_discount[month] += tenant_data * @rentable_sf
                @delay_start_discount_for_term_greater_12[month] += tenant_data * @rentable_sf
              end
              tenant_data = 0.0
            end
          end
          landlord_data = landlord_expenses( datatype: key, bill_period: period )
          @results[store][:tenant_costs_per_year][key] ||= 0.0
          if (@expenses[key][:calculation_type] == 'with_start_and_base_year')
              @results[store][:tenant_costs_per_year][key] = (tenant_data * 12.0 if tenant_data) || 0.0
          else
            @results[store][:tenant_costs_per_year][key] += tenant_data if tenant_data
          end
          @results[store][:tenant_costs_per_year][:expenses][key] = (tenant_data * 12.0 if tenant_data) || 0.0
          @results[store][:landlord_costs_per_year][:expenses][key] = (landlord_data * -12 if landlord_data) || 0.0
          @results[store][:landlord_costs_per_year][:landlord_expenses] -= landlord_data if landlord_data
        }
        @results[store][:tenant_costs_per_year][:tenant_ti] ||= 0.0
        @results[store][:tenant_costs_per_year][:tenant_ti] = @tenant_ti if period == 0

        if @interest_rate == 0.0 and period == 1
          @results[store][:landlord_costs_per_year][:tenant_improvements] = @tenant_improvements * -1
        elsif @interest_rate != 0.0
          period_months = (@term_months - ((period - 1) * 12)) > 12 ? 12 : (@term_months - ((period - 1) * 12))
          rate = Finance::Rate.new(@interest_rate, :apr, :duration => @term_months)
          amortization = Finance::Amortization.new(@tenant_improvements * @rentable_sf, rate)
          @results[store][:landlord_costs_per_year][:tenant_improvements] = ((amortization.payment * period_months) / @rentable_sf)
        else
          @results[store][:landlord_costs_per_year][:tenant_improvements] ||= 0.0
        end
      end

      if (store == 0 and !@is_base_rent and @term_months % 12 != 0)
        remainder = 12 - (@term_months % 12)
        1.upto(remainder) do |r|
          month = @term_months + r
          s, period = new_bill_period(store, period, month)
          #@results[store][:tenant_costs_per_year][:pre_free_rent] = @rents[-1] * 12.0
          @results[store][:tenant_costs_per_year][:base_rent_increase], @results[store][:tenant_costs_per_year][:non_prorated_base_rent_increase] = base_rent_increase(store, period, month)
        end
      end

      landlord = @results.merge({})
      period = 1
      @results.each do |store, value|
        @results[store][:tenant_costs_per_year][:free_rent] = free_rent(store, period)
        @results[store][:tenant_costs_per_year][:post_free_rent] = post_free_rent(store, period)
        landlord[store][:free_rent_monthly_value_per_year] = free_rent_per_month(store, period)
        landlord[store][:total_value_free_rent] = landlord[store][:free_rent_monthly_value_per_year] * free_rent_months(store,period)
        # landlord cashflow
        landlord[store][:landlord_costs_per_year][:commissions_per_sf]  ||= 0
        landlord[1][:landlord_costs_per_year][:commissions_per_sf]       -= total_commissions(landlord, store, period) if @results.length > 1
        landlord[store][:landlord_costs_per_year][:commissions_per_sf]   -= total_commissions(landlord, store, period) if @results.length == 1
        @results[store][:landlord_costs_per_year][:landlord_reimbursed_expenses] ||= 0.0
        @expenses.keys.each {|key|
          if ( @expenses[key][:calculation_type] == 'with_start_and_base_year' and ((period * 12 % @term_months % 12) > 0))
            @results[store][:tenant_costs_per_year][key] = @results[store][:tenant_costs_per_year][key] *  (1 - ((period * 12 - @term_months) / 12.0))
          end
          if ( @expenses[key][:calculation_type] == 'with_start_and_base_year' && @gross_free_rent)
            factor = 12
            if period * 12 > @term_months
              factor = 12 - (period*12 -@term_months)
            end
            @results[store][:landlord_costs_per_year][:landlord_reimbursed_expenses] += ((@results[store][:tenant_costs_per_year][key].to_f)/factor)*(factor-free_rent_months(store,period))
          else
            @results[store][:landlord_costs_per_year][:landlord_reimbursed_expenses] += @results[store][:tenant_costs_per_year][key].to_f
          end
        }
        period  = period + 1
      end
      # merge the landlord
      @results.merge(landlord)
      summary = @results.merge({
        :summary => {}
      })
      tenant_cummulative_total   = 0.0
      landlord_cummulative_total = 0.0
      period = 0

      @results.each do |store, value|
        period += 1
        summary[:tenant_summary] ||= {}
        summary[:landlord_summary] ||= {}

        # free rent
        summary[store][:free_rent_breakdown] = breakdown(period, 0, value[:free_rent_monthly_value_per_year])
        summary[:tenant_summary][:free_rent_breakdown_sum] ||= 0
        summary[:tenant_summary][:free_rent_breakdown_sum] += summary[store][:free_rent_breakdown][:sum]

        # tenant cash flow
        tenant_per_sf_total    = 0.0
        tenant_monthly_average = 0.0
        tenant_per_annum_total = 0.0

        #tenant_per_sf_total += value[:tenant_costs_per_year][:base_rent_increase]
        tenant_per_sf_total += value[:tenant_costs_per_year][:post_free_rent]
        tenant_per_sf_total += value[:landlord_costs_per_year][:landlord_reimbursed_expenses]

        tenant_monthly_average   = tenant_per_sf_total * @rentable_sf / 12.0
        tenant_per_annum_total   = tenant_per_sf_total * @rentable_sf
        tenant_cummulative_total += tenant_per_annum_total

        non_prorated_tenant_per_sf_total = 0.0
        non_prorated_tenant_per_sf_total += value[:tenant_costs_per_year][:non_prorated_base_rent_increase]
        non_prorated_tenant_per_sf_total += value[:tenant_costs_per_year][:expenses].map(&:last).reduce(:+) if not value[:tenant_costs_per_year][:expenses].empty?
        free_rent_prorated = non_prorated_tenant_per_sf_total - value[:tenant_costs_per_year][:non_prorated_base_rent_increase]
        if @is_base_rent
          non_prorated_tenant_per_sf_total += pre_free_rent(1, 1, 0, true) #value[:tenant_costs_per_year][:pre_free_rent]
        else
          non_prorated_tenant_per_sf_total += pre_free_rent(store,period,0,true) #+= pre_free_rent(1, 1, 0, true) #value[:tenant_costs_per_year][:pre_free_rent]
        end

        non_prorated_tenant_monthly_average = non_prorated_tenant_per_sf_total * @rentable_sf / 12.0
        free_rent_prorated_monthly_average = free_rent_prorated * @rentable_sf / 12.0

        summary[store][:tenant_breakdown] = breakdown_delay_start(period, non_prorated_tenant_monthly_average, free_rent_prorated_monthly_average)
        if @term_months < 12.0
          @pv_less_than_12 = pv_breakdown(period, non_prorated_tenant_monthly_average, free_rent_prorated_monthly_average)
        end

        summary[:tenant_summary][:cummulative_total_breakdown_sum] ||= 0.0
        summary[:tenant_summary][:cummulative_total_breakdown_sum] += summary[store][:tenant_breakdown][:sum]

        summary[store][:tenant_summary][:per_sf_total] = tenant_per_sf_total
        summary[store][:tenant_summary][:monthly_average] = tenant_monthly_average
        summary[store][:tenant_summary][:per_annum_total] = tenant_per_annum_total
        summary[store][:tenant_summary][:cummulative_total] = tenant_cummulative_total
        summary[:tenant_summary]['tenant_expenses_$/sf'.to_sym] ||= 0.0 #
        summary[:tenant_summary]['tenant_expenses_$/sf'.to_sym] += @results[store][:landlord_costs_per_year][:landlord_reimbursed_expenses]
        summary[:tenant_summary][:free_rent_total_value] ||= 0.0
        summary[:tenant_summary][:free_rent_total_value] += @results[store][:total_value_free_rent]

        landlord_per_sf_total    = 0.0
        landlord_monthly_average = 0.0
        landlord_per_annum_total = 0.0

        #landlord_per_sf_total += value[:tenant_costs_per_year][:base_rent_increase]
        landlord_per_sf_total += value[:tenant_costs_per_year][:post_free_rent]
        landlord_per_sf_total += value[:landlord_costs_per_year][:landlord_reimbursed_expenses]
        landlord_per_sf_total += value[:landlord_costs_per_year][:landlord_expenses].to_f
        landlord_per_sf_total += value[:landlord_costs_per_year][:tenant_improvements].to_f
        landlord_per_sf_total += value[:landlord_costs_per_year][:commissions_per_sf].to_f
        landlord_per_sf_total -= @additional_ll_allowance.to_f if store == 1

        if @term_months < 12.0
          landlord_monthly_average   = landlord_per_sf_total * @rentable_sf / @term_months.to_f
          landlord_per_annum_total   = landlord_monthly_average * @term_months
        else
          landlord_monthly_average   = landlord_per_sf_total * @rentable_sf / 12.0
          landlord_per_annum_total   = landlord_monthly_average * 12.0
        end

        landlord_cummulative_total += landlord_per_annum_total

        if @term_months < 12.0
          @ll_expenses_for_less_than_12 = []
          expense_for_less_than_12 = 0.0
          1.upto(12) do |mon|
            @ll_expenses_for_less_than_12[mon] = 0.0
            @expenses.keys.each {|key|
              if @gross_free_rent
                if @free_rent_interval.include? mon
                  @ll_expenses_for_less_than_12[mon] += (@expenses[key][:cost].to_f/12) * @rentable_sf
                end
              else
                if @expenses[key][:calculation_type] == 'generic'
                  @ll_expenses_for_less_than_12[mon] = 0.0
                else
                  if ( @expenses[key][:delay_start_date].nil?)
                    expense_for_less_than_12 += (@expenses[key][:cost].to_f/12) * @rentable_sf
                    @ll_expenses_for_less_than_12[mon] += (@expenses[key][:cost].to_f/12) * @rentable_sf
                  else
                    if @expenses[key][:delay_start_date].to_date >= @commencement + mon.months
                      expense_for_less_than_12 += (@expenses[key][:cost].to_f/12) * @rentable_sf
                      @ll_expenses_for_less_than_12[mon] += (@expenses[key][:cost].to_f/12) * @rentable_sf
                    end
                  end
                end
              end
            }
          end
          expense_for_less_than_12 = (expense_for_less_than_12) * -1 + (value[:landlord_costs_per_year][:tenant_improvements].to_f + value[:landlord_costs_per_year][:commissions_per_sf].to_f - @additional_ll_allowance.to_f) * @rentable_sf

          monthly_average = (@rentable_sf * @base_rent) / 12
          annual_income_total_expense = 0.0
          annual_income_total_expense += value[:landlord_costs_per_year][:landlord_reimbursed_expenses]
          annual_income_total_expense += value[:landlord_costs_per_year][:landlord_expenses].to_f
          annual_income_total_expense += value[:landlord_costs_per_year][:tenant_improvements].to_f
          annual_income_total_expense += value[:landlord_costs_per_year][:commissions_per_sf].to_f
          annual_income_total_expense -= @additional_ll_allowance.to_f
          annual_income_total_expense = annual_income_total_expense * @rentable_sf
          @pv_annual_ll_income_average = pv_annual_income_average(period, monthly_average, expense_for_less_than_12)

          @pv_ll_income_less_than_12 = pv_ll_income_less_than_12(period, monthly_average, annual_income_total_expense)
        end
        tenant_improvement_and_commission = 0.0
        non_prorated_landlord_per_sf_total = 0.0
        non_prorated_landlord_per_sf_total += value[:tenant_costs_per_year][:expenses].map(&:last).reduce(:+) if not value[:tenant_costs_per_year][:expenses].empty?
        non_prorated_landlord_per_sf_total += value[:landlord_costs_per_year][:expenses].map(&:last).reduce(:+) if not value[:landlord_costs_per_year][:expenses].empty?
        if @interest_rate != 0.0
          non_prorated_landlord_per_sf_total += ((Finance::Amortization.new(@tenant_improvements * @rentable_sf, Finance::Rate.new(@interest_rate, :apr, :duration => @term_months)).payment * 12) / @rentable_sf)
        else
          tenant_improvement_and_commission += value[:landlord_costs_per_year][:tenant_improvements].to_f
        end
        tenant_improvement_and_commission += value[:landlord_costs_per_year][:commissions_per_sf].to_f
        free_rent_landlord_prorated_sf_total = non_prorated_landlord_per_sf_total
        if @is_base_rent
          non_prorated_landlord_per_sf_total += pre_free_rent(1, 1, 0, false) #value[:tenant_costs_per_year][:pre_free_rent]
        else
          non_prorated_landlord_per_sf_total += pre_free_rent(store,period,0,true) #value[:tenant_costs_per_year][:pre_free_rent]
        end

        non_prorated_landlord_per_sf_total += value[:tenant_costs_per_year][:non_prorated_base_rent_increase]

        if @term_months < 12
          non_prorated_landlord_monthly_average = non_prorated_landlord_per_sf_total * @rentable_sf / @term_months.to_f
          free_rent_landlord_prorated_monthly_average = free_rent_landlord_prorated_sf_total * @rentable_sf / @term_months.to_f
        else
          non_prorated_landlord_monthly_average = non_prorated_landlord_per_sf_total * @rentable_sf / 12.0
          free_rent_landlord_prorated_monthly_average = free_rent_landlord_prorated_sf_total * @rentable_sf / 12.0
        end



        if @term_months < 12
          #summary[store][:landlord_breakdown] = landlord_breakdown_less_than_12( period, (@rentable_sf * @base_rent / 12), tenant_improvement_and_commission * @rentable_sf)
          improvement_and_additional_ll_allowence = 0.0
          commission = 0.0
          rent = 0.0
          expense = 0.0
          if @is_base_rent
            rent += pre_free_rent(1, 1, 0, false)
          else
            rent += pre_free_rent(store,period,0,true)
          end
          rent += value[:tenant_costs_per_year][:non_prorated_base_rent_increase]
          rent = (rent/@term_months) * @rentable_sf
          commission = value[:landlord_costs_per_year][:commissions_per_sf].to_f * @rentable_sf if period == 1
          if @interest_rate != 0.0
            improvement_and_additional_ll_allowence += (Finance::Amortization.new((@tenant_improvements + @additional_ll_allowance) * @rentable_sf, Finance::Rate.new(@interest_rate, :apr, :duration => @term_months)).payment)
          else
            improvement_and_additional_ll_allowence += (value[:landlord_costs_per_year][:tenant_improvements].to_f - @additional_ll_allowance) * @rentable_sf
          end

          summary[store][:landlord_breakdown] = breakdown_for_ll_with_discount_with_interest_less_than_12(period, rent, commission, improvement_and_additional_ll_allowence)
          summary[:landlord_summary][:cummulative_total_breakdown_sum] ||= 0.0
          summary[:landlord_summary][:cummulative_total_breakdown_sum] += summary[store][:landlord_breakdown][:sum]

          #PV annual income average
          @pv_annual_ll_income_average = breakdown_for_ll_with_discount_with_interest_pv_annual_income_average_less_than_12(period, rent, commission, improvement_and_additional_ll_allowence)



          landlord_cummulative_total_new = breakdown_for_ll_total_income_less_than_12(period, rent, commission, improvement_and_additional_ll_allowence)
          summary[:landlord_summary][:cummulative_total] ||= 0.0
          summary[:landlord_summary][:cummulative_total] += landlord_cummulative_total_new[:sum]

        else
            improvement_and_additional_ll_allowence = 0.0
            commission = 0.0
            expense = 0.0
            rent = 0.0
            expense += value[:tenant_costs_per_year][:expenses].map(&:last).reduce(:+) if not value[:tenant_costs_per_year][:expenses].empty?
            expense += value[:landlord_costs_per_year][:expenses].map(&:last).reduce(:+) if not value[:landlord_costs_per_year][:expenses].empty?
            if @is_base_rent
              rent += pre_free_rent(1, 1, 0, false)
            else
              rent += pre_free_rent(store,period,0,true)
            end
            rent += value[:tenant_costs_per_year][:non_prorated_base_rent_increase]
            rent +=expense
            rent = (rent/12) * @rentable_sf
            expense = (expense/12) * @rentable_sf
            commission = value[:landlord_costs_per_year][:commissions_per_sf].to_f * @rentable_sf if period == 1
            if @interest_rate != 0.0
              improvement_and_additional_ll_allowence += (Finance::Amortization.new((@tenant_improvements + @additional_ll_allowance) * @rentable_sf, Finance::Rate.new(@interest_rate, :apr, :duration => @term_months)).payment)
            else
              improvement_and_additional_ll_allowence += (value[:landlord_costs_per_year][:tenant_improvements].to_f - @additional_ll_allowance) * @rentable_sf
            end

            summary[store][:landlord_breakdown] = breakdown_for_ll_with_discount_with_interest(period, rent, expense, commission, improvement_and_additional_ll_allowence)
            summary[:landlord_summary][:cummulative_total_breakdown_sum] ||= 0.0
            summary[:landlord_summary][:cummulative_total_breakdown_sum] += summary[store][:landlord_breakdown][:sum]
            landlord_cummulative_total_new = breakdown_for_ll_total_income(period, rent, expense, commission, improvement_and_additional_ll_allowence)
            summary[:landlord_summary][:cummulative_total] ||= 0.0
            summary[:landlord_summary][:cummulative_total] += landlord_cummulative_total_new[:sum]
        end



        summary[store][:landlord_summary][:per_sf_total] = landlord_per_sf_total
        summary[store][:landlord_summary][:monthly_average] = landlord_monthly_average
        summary[store][:landlord_summary][:per_annum_total] = landlord_per_annum_total
        #summary[store][:landlord_summary][:cummulative_total] = landlord_cummulative_total

      end



      summary[:summary][:total_rent] = summary[store][:tenant_summary][:cummulative_total] + ((@tenant_ti + @additional_tenant_cost) * @rentable_sf)
      summary[:summary][:present_value_total_rent] = summary[:tenant_summary][:cummulative_total_breakdown_sum]
      if @term_months < 12
        @delay_start_discount[0] = 0.0
        delay_start_total_value = @delay_start_discount.inject(0){|sum,x| sum + x }
        summary[:summary]['annual_rent_(average)'.to_sym] = ((summary[:summary][:total_rent] + summary[:tenant_summary][:free_rent_total_value] + delay_start_total_value) / @term_months * 12.0) - summary[:tenant_summary][:free_rent_total_value] - delay_start_total_value
        summary[:summary]['pv_annual_rent_(average)'.to_sym] = @pv_less_than_12[:sum].to_f
      else
        summary[:summary]['annual_rent_(average)'.to_sym] = summary[:summary][:total_rent] / @term_months * 12.0
        summary[:summary]['pv_annual_rent_(average)'.to_sym] = summary[:summary][:present_value_total_rent] / @term_months * 12.0
      end

      summary[:summary]['annual_rent_($/sf)'.to_sym] = summary[:summary]['annual_rent_(average)'.to_sym] / @rentable_sf
      summary[:summary]['tenant_effective_rent_($/sf)'.to_sym] = summary[:summary]['pv_annual_rent_(average)'.to_sym] / @rentable_sf
      summary[:summary]['tenant_expenses_$/sf'.to_sym] = summary[:tenant_summary]['tenant_expenses_$/sf'.to_sym] / @term_months * 12.0
      summary[:summary]['avg_base_rent_(no_expenses)_$/sf'.to_sym] = summary[:summary]['annual_rent_($/sf)'.to_sym] - summary[:summary]['tenant_expenses_$/sf'.to_sym]
      summary[:summary][:tenant_improvements] = @tenant_improvements * @rentable_sf

      if @interest_rate == 0.0
        summary[:summary]['tenant_improvements_+_amortized_interest'.to_sym] = summary[:summary][:tenant_improvements]
        summary[:summary]['tenant_improvements_+_amortized_interest_($/sf)'.to_sym] = summary[:summary][:tenant_improvements] / @rentable_sf
      else
        rate = Finance::Rate.new(@interest_rate, :apr, :duration => @term_months)
        amortization = Finance::Amortization.new(summary[:summary][:tenant_improvements], rate)
        summary[:summary]['tenant_improvements_+_amortized_interest'.to_sym] = ((amortization.payment * @term_months)).round(2) * -1
        summary[:summary]['tenant_improvements_+_amortized_interest_($/sf)'.to_sym] = ((amortization.payment * @term_months) / @rentable_sf).round(2) * -1
      end

      summary[:summary][:free_rent] = summary[:tenant_summary][:free_rent_total_value]
      summary[:summary][:pv_of_free_rent] = summary[:tenant_summary][:free_rent_breakdown_sum]
      # Remove this attribute as per Adrian request.
=begin
      if @term_months < 12
        summary[:summary][:pv_free_rent_per_annum] = summary[:summary][:pv_of_free_rent] / @term_months * @term_months.to_f
      else
        summary[:summary][:pv_free_rent_per_annum] = summary[:summary][:pv_of_free_rent] / @term_months * 12.0
      end
=end

      summary[:summary]['pv_free_rent_$/sf'.to_sym] = summary[:summary][:pv_of_free_rent] / @rentable_sf

      summary[:summary]['total_ll_concessions_$/sf'.to_sym] = summary[:summary]['tenant_improvements_+_amortized_interest_($/sf)'.to_sym] + summary[:summary]['pv_free_rent_$/sf'.to_sym] + @additional_ll_allowance

      summary[:summary][:total_ll_income] = summary[:landlord_summary][:cummulative_total]
      summary[:summary][:present_value_of_ll_income] = summary[:landlord_summary][:cummulative_total_breakdown_sum]
      if @term_months < 12
        #summary[:summary][:present_value_of_ll_income] = @pv_ll_income_less_than_12[:sum].to_f
        summary[:summary]['pv_annual_income_(average)'.to_sym] = @pv_annual_ll_income_average[:sum].to_f
        summary[:summary]['ll_effective_rent_($/sf)'.to_sym] = summary[:summary]['pv_annual_income_(average)'.to_sym] / @rentable_sf
      else
        summary[:summary]['pv_annual_income_(average)'.to_sym] = summary[:summary][:present_value_of_ll_income] / @term_months * 12.0
        summary[:summary]['ll_effective_rent_($/sf)'.to_sym] = summary[:summary]['pv_annual_income_(average)'.to_sym] / @rentable_sf
      end
      # Remove this attribute as per Adrian request.
=begin
      summary[:summary][:landlord_margin] = if summary[:summary]['tenant_effective_rent_($/sf)'.to_sym] <= 0
                                              nil
                                            else
                                              (summary[:summary]['ll_effective_rent_($/sf)'.to_sym].to_f / summary[:summary]['tenant_effective_rent_($/sf)'.to_sym].to_f) * 100.0
                                            end
=end


      if summary[0].blank?
        summary[0] = summary[1]
      end
      # Remove this attribute as per Adrian request.
=begin
      summary[:summary][:fs_equivalent] = if (summary[1])
                                            summary[0][:tenant_costs_per_year][:pre_free_rent].to_f + summary[0][:tenant_costs_per_year][:expenses].map{|h,v| v}.sum
                                          else
                                            summary[0][:tenant_costs_per_year][:pre_free_rent].to_f + summary[0][:tenant_costs_per_year][:expenses].map{|h,v| v}.sum
                                          end
=end
      summary[:free_rent_summary]= {}
      summary[:free_rent_summary][:free_rent_total] = @free_rent

      @results.merge(summary)
    end


    private

    def present_value(expense = 0, period = 1)
      expense / ( (1 + (@discount_rate / 12.0)) ** period )
    end

    def new_bill_period(store = 1, bill_period = 1, month = 1)
      if (month > (bill_period * 12.0) and store > 0)
        bill_period += 1
        store = (month + 11 < @term_months) ? bill_period : 0
      end
      year_ending = (store == 0) ?  @expiration : (((@commencement + bill_period.years) - 1.month).end_of_month)
      data = data_initialization(year_ending)
      data2 = data_initialization(year_ending)
      @results[store] = data if @results[store].nil?
      @without_delay[store] = data2 if @without_delay[store].nil?
      [store, bill_period]
    end

    def data_initialization year_ending
      {
          :year_ending => year_ending,
          #:tenant_costs_per_month => {},
          #:landlord_costs_per_month => {},
          :tenant_costs_per_year => {},
          :landlord_costs_per_year => {},
          :tenant_summary => {},
          :landlord_summary => {},
          :tenant_breakdown => {},
          :landlord_breakdown => {}
      }
    end

    def landlord_expenses(options = { :datatype => '' })
      raise "Type not defined" if options[:datatype].blank?
      datatype               = options[:datatype]
      bill_period            = options[:bill_period]
      increase_percent_value = 1.0 + (@expenses[datatype][:increase_percent].to_f / 100)
      cost_value             = @expenses[datatype][:cost].to_f
      if bill_period > 1
        (cost_value * increase_percent_value ** (bill_period - 1)) / 12.0
      else
        cost_value / 12.0
      end
    end

    def tenant_expenses(options = { :datatype => '' })
      raise "Type not defined" if options[:datatype].blank?
      month                  = options[:month]
      datatype               = options[:datatype]
      bill_period            = options[:bill_period]
      increase_percent = 1.0 + (@expenses[datatype][:increase_percent].to_f / 100)
      calculated_value       = nil

      if ( uses_start_date?(datatype) )
        cost_value = @expenses[datatype][:cost].to_f
        start_date = if (@expenses[datatype][:start_date].blank?)
                       @commencement + 1.year
                     else
                       (Date.parse(@expenses[datatype][:start_date]) if @expenses[datatype][:start_date].is_a? String) || @expenses[datatype][:start_date]
                     end
        calculation_date = (@commencement + month.months - 1.month).end_of_month
        start_bill_period = start_date.year - @commencement.year
        if (calculation_date >= start_date)
          calculated_value = ( ((increase_percent ** (bill_period - start_bill_period)) * cost_value) - cost_value) / 12.0
        else
          calculated_value = 0
        end
      else
        # check if previous period's value exists, otherwise use data from user ...
        cost_value = options[:previous_cost_value] || @expenses[datatype][:cost].to_f

        # don't add increase percentage in the beginning
        increase_percent = 1.0 if month <= 12.0
        calculated_value = (cost_value * increase_percent) / 12.0
      end
      calculated_value
    end

    def total_expense_cost(cashflow = 'tenant_cost_per_year', key = '', period = 0)
      if period == 1
        @results[period-1].nil? ? nil : @results[period-1][cashflow.to_sym][key]
      else
        @without_delay[period-1].nil? ? nil : @without_delay[period-1][cashflow.to_sym][key]
      end

    end

    def total_commissions(data, store, bill_period = 1)
      #=C39*0.06+C38*0.06+D39*0.04+D38*0.04+E39*0.04+E38*0.04+F39*0.03+F38*0.03+G39*0.02+G38*0.02+H39*0.02+H38*0.02+I39*0.02+I38*0.02+J39*0.02+J38*0.02+K39*0.02+K38*0.02
      rent = data[store][:tenant_costs_per_year][:post_free_rent] # + data[store][:tenant_costs_per_year][:base_rent_increase]
      case bill_period
      when 1
        0.06 * rent
      when 2..3
        0.04 * rent
      when 4
        0.03 * rent
      else
        0.02 * rent
      end
    end

    def base_rent_increase(store, bill_period, month)
      return [0, 0] if month <= 12.0 # only calculate if more than 12.0 months
      return [0, 0] if !@is_base_rent
      store = bill_period if store  == 0
      rent = total_expense_cost('tenant_costs_per_year', :pre_free_rent, store).to_f
      calculated_rent = rent + total_expense_cost('tenant_costs_per_year', :base_rent_increase, store).to_f
      if @rent_escalation_fixed
        non_prorated = ((calculated_rent + @annual_escalation) - rent)
      else
        non_prorated = ((calculated_rent * (1 + @annual_escalation)) - rent)
      end
      [prorate(store, bill_period) * non_prorated, non_prorated]
    end

    def pre_free_rent(store, period, month, non_prorated=false)
      if @is_base_rent
        if @term_months < 12
          if (non_prorated)
            return @base_rent
          else
            return (@term_months / 12.0) * @base_rent
          end
        elsif (store == 0 and (@term_months % 12 > 0)) # prorate at end of lease
          return @rents[0] * (@term_months % 12)
        else
          return @base_rent
        end
      end
      max = period * 12.0 - 1
      min = max - 12.0 + 1
      if (max+1) > @term_months && !@is_base_rent
        num_of_month = @term_months - min
        annual_rent = ((@rents[min..@term_months-1].sum)/num_of_month)*12
      else
        @rents[min..max].sum
      end
    end

    def free_rent_months(store, period)
      interval = period * 12
      start = interval - 12 + 1
      free_months = 0
      start.upto(interval) do |m|
        free_months += 1 if @free_rent_interval.include? m
      end
      free_months
    end
    def free_rent(store, period)
      #= D35/12*(D21+D22)+D35/12*D20
      #= free_rent_months/12*(pre_free_rent+base_rent_increase)+ free_rent_months/12*pre_free_rent
      free_months = free_rent_months(store, period)
      if @term_months < 12
        (free_months / @term_months.to_f) * (@results[1][:tenant_costs_per_year][:pre_free_rent] + @results[1][:tenant_costs_per_year][:base_rent_increase])
      else
        if @is_base_rent && @annual_escalation.to_f == 0.0
          (free_months / 12.0) * (@results[1][:tenant_costs_per_year][:pre_free_rent] + @results[1][:tenant_costs_per_year][:base_rent_increase])
        elsif @is_base_rent && @annual_escalation.to_f != 0.0
          num_full_years = (@term_months / 12.0).floor
          if period <= num_full_years
            (free_months / 12.0) * (@results[store][:tenant_costs_per_year][:pre_free_rent] + @results[store][:tenant_costs_per_year][:base_rent_increase])
          else
            (free_months / (@term_months - num_full_years * 12).to_f) * (@results[store][:tenant_costs_per_year][:pre_free_rent] + @results[store][:tenant_costs_per_year][:base_rent_increase])
          end
        else
          (free_months / 12.0) * (@results[store][:tenant_costs_per_year][:pre_free_rent] + @results[store][:tenant_costs_per_year][:base_rent_increase])
        end
      end

    end

    def post_free_rent(store, period)
      num_full_years = (@term_months / 12.0).floor
      if period > num_full_years && !@is_base_rent
        ((@term_months % 12) / 12.0) * @results[store][:tenant_costs_per_year][:pre_free_rent] - @results[store][:tenant_costs_per_year][:free_rent]
      else
        @results[store][:tenant_costs_per_year][:pre_free_rent] + @results[store][:tenant_costs_per_year][:base_rent_increase] - @results[store][:tenant_costs_per_year][:free_rent]
      end
    end

    def breakdown(store, expense, without_rent_expense)

      #$C$15 = discount_rate
      #E52 =IF(G7>E18,0,IF(AND(C6>24,C6<=36,G7=C5),G4*G6^2,IF(AND(C6>36,G7=C5),G4*G6^2,IF(AND(C6>36,E18-G7<=365),G4*G6-G4,IF(AND(C6>36,E18-G7<=730),G4*G6^2-G4,IF(AND(C6>24,C6<=36,E18-G7<=365),(G4*G6-G4),IF(AND(C6>24,C6<=36,E18-G7<=730),(G4*G6^2-G4),IF(C6<=24,0,G4*G6-G4))))))))+IF(I7>E18,0,IF(AND(C6>24,C6<=36,I7=C5),I4*I6^2,IF(AND(C6>36,I7=C5),I4*I6^2,IF(AND(C6>36,E18-I7<=365),I4*I6-I4,IF(AND(C6>36,E18-I7<=730),I4*I6^2-I4,IF(AND(C6>24,C6<=36,E18-I7<=365),(I4*I6-I4),IF(AND(C6>24,C6<=36,E18-I7<=730),(I4*I6^2-I4),IF(C6<=24,0,I4*I6-I4))))))))+IF($K$4=0,0,IF(AND($C$6>24,$C$6<=36),(D44*$K$6),IF($C$6>36,D44*K6,0)))+IF($M$4=0,0, IF(AND($C$6>24,$C$6<=36),(D45*$M$6), IF($C$6>36,D45*M6,0)))+IF($O$4=0,0, IF(AND($C$6>24,$C$6<=36),(D46*$O$6), IF($C$6>36,D46*O6,0)))+IF($S$4=0,0, IF(AND($C$6>24,$C$6<=36),(D48*$S$6), IF($C$6>36,D48*$S$6,0)))
      #E53 =E52*$C$13/12
      #E54 =IF(E19=0,0,C8+E157+((1+C14)^2*C8-C8)+IF(G7>E18,0,IF(AND(C6>24,C6<=36,G7=C5),G4*G6^2,IF(AND(C6>36,G7=C5),G4*G6^2,IF(AND(C6>36,E18-G7<=365),G4*G6-G4,IF(AND(C6>36,E18-G7<=730),G4*G6^2-G4,IF(AND(C6>24,C6<=36,E18-G7<=365),(G4*G6-G4),IF(AND(C6>24,C6<=36,E18-G7<=730),(G4*G6^2-G4),IF(C6<=24,0,G4*G6-G4))))))))+IF(I7>E18,0,IF(AND(C6>24,C6<=36,I7=C5),I4*I6^2,IF(AND(C6>36,I7=C5),I4*I6^2,IF(AND(C6>36,E18-I7<=365),I4*I6-I4,IF(AND(C6>36,E18-I7<=730),I4*I6^2-I4,IF(AND(C6>24,C6<=36,E18-I7<=365),(I4*I6-I4),IF(AND(C6>24,C6<=36,E18-I7<=730),(I4*I6^2-I4),IF(C6<=24,0,I4*I6-I4))))))))+IF($K$4=0,0,IF(AND($C$6>24,$C$6<=36),(D44*$K$6),IF($C$6>36,D44*K6,0)))+IF($M$4=0,0,IF(AND($C$6>24,$C$6<=36),(D45*$M$6),IF($C$6>36,D45*M6,0)))+IF($O$4=0,0,IF(AND($C$6>24,$C$6<=36),(D46*$O$6),IF($C$6>36,D46*O6,0)))+IF($S$4=0,0,IF(AND($C$6>24,$C$6<=36),(D48*$S$6),IF($C$6>36,D48*$S$6,0))))
      #E55 =E54*C13/12
      #=IF(E23=1,PV($C$15/12,24,,-E53,1),IF($C$6<25,0,PV($C$15/12,24,,-$E$55,1))
      bd = {
        :sum => 0.0
      }
      0.upto(11) do |month|
        period = ( (store * 12.0) - 12.0 + month )
        if @free_rent_interval.include?((period + 1).to_i)
          #PV($C$15/12,24,,-E53,1)
          bd[period] = (period >= @term_months) ? 0.00 : present_value(without_rent_expense, period)
        else
          #PV($C$15/12,24,,-$E$55,1)
          bd[period] = (period >= @term_months) ? 0.00 : present_value(expense, period)
        end
        bd[:sum] += bd[period]
      end
      bd
    end

    def breakdown_delay_start(store, total, without_rent_expense)
      total_after_delay_start_discount = total
      expense_after_delay_start_discount = without_rent_expense
      bd = {
          :sum => 0.0
      }
      0.upto(11) do |month|
        total_after_delay_start_discount = total_after_delay_start_discount - ( @delay_start_discount[(store * 12)-12+month+1].present? ? @delay_start_discount[(store * 12)-12+month+1] : 0 )
        expense_after_delay_start_discount = expense_after_delay_start_discount - ( @delay_start_discount[(store * 12)-12+month+1].present? ? @delay_start_discount[(store * 12)-12+month+1] : 0 )
        period = ( (store * 12.0) - 12.0 + month )
        if @free_rent_interval.include?((period + 1).to_i)
          #PV($C$15/12,24,,-E53,1)
          bd[period] = (period >= @term_months) ? 0.00 : present_value(expense_after_delay_start_discount, period)
        else
          bd[period] = (period >= @term_months) ? 0.00 : present_value(total_after_delay_start_discount, period)
        end
        bd[:sum] += bd[period]
        total_after_delay_start_discount = total
        expense_after_delay_start_discount = without_rent_expense
      end
      bd
    end

    def landlord_breakdown_less_than_12(store, monthly_average, improvement_and_commission)

      #$C$15 = discount_rate
      #E52 =IF(G7>E18,0,IF(AND(C6>24,C6<=36,G7=C5),G4*G6^2,IF(AND(C6>36,G7=C5),G4*G6^2,IF(AND(C6>36,E18-G7<=365),G4*G6-G4,IF(AND(C6>36,E18-G7<=730),G4*G6^2-G4,IF(AND(C6>24,C6<=36,E18-G7<=365),(G4*G6-G4),IF(AND(C6>24,C6<=36,E18-G7<=730),(G4*G6^2-G4),IF(C6<=24,0,G4*G6-G4))))))))+IF(I7>E18,0,IF(AND(C6>24,C6<=36,I7=C5),I4*I6^2,IF(AND(C6>36,I7=C5),I4*I6^2,IF(AND(C6>36,E18-I7<=365),I4*I6-I4,IF(AND(C6>36,E18-I7<=730),I4*I6^2-I4,IF(AND(C6>24,C6<=36,E18-I7<=365),(I4*I6-I4),IF(AND(C6>24,C6<=36,E18-I7<=730),(I4*I6^2-I4),IF(C6<=24,0,I4*I6-I4))))))))+IF($K$4=0,0,IF(AND($C$6>24,$C$6<=36),(D44*$K$6),IF($C$6>36,D44*K6,0)))+IF($M$4=0,0, IF(AND($C$6>24,$C$6<=36),(D45*$M$6), IF($C$6>36,D45*M6,0)))+IF($O$4=0,0, IF(AND($C$6>24,$C$6<=36),(D46*$O$6), IF($C$6>36,D46*O6,0)))+IF($S$4=0,0, IF(AND($C$6>24,$C$6<=36),(D48*$S$6), IF($C$6>36,D48*$S$6,0)))
      #E53 =E52*$C$13/12
      #E54 =IF(E19=0,0,C8+E157+((1+C14)^2*C8-C8)+IF(G7>E18,0,IF(AND(C6>24,C6<=36,G7=C5),G4*G6^2,IF(AND(C6>36,G7=C5),G4*G6^2,IF(AND(C6>36,E18-G7<=365),G4*G6-G4,IF(AND(C6>36,E18-G7<=730),G4*G6^2-G4,IF(AND(C6>24,C6<=36,E18-G7<=365),(G4*G6-G4),IF(AND(C6>24,C6<=36,E18-G7<=730),(G4*G6^2-G4),IF(C6<=24,0,G4*G6-G4))))))))+IF(I7>E18,0,IF(AND(C6>24,C6<=36,I7=C5),I4*I6^2,IF(AND(C6>36,I7=C5),I4*I6^2,IF(AND(C6>36,E18-I7<=365),I4*I6-I4,IF(AND(C6>36,E18-I7<=730),I4*I6^2-I4,IF(AND(C6>24,C6<=36,E18-I7<=365),(I4*I6-I4),IF(AND(C6>24,C6<=36,E18-I7<=730),(I4*I6^2-I4),IF(C6<=24,0,I4*I6-I4))))))))+IF($K$4=0,0,IF(AND($C$6>24,$C$6<=36),(D44*$K$6),IF($C$6>36,D44*K6,0)))+IF($M$4=0,0,IF(AND($C$6>24,$C$6<=36),(D45*$M$6),IF($C$6>36,D45*M6,0)))+IF($O$4=0,0,IF(AND($C$6>24,$C$6<=36),(D46*$O$6),IF($C$6>36,D46*O6,0)))+IF($S$4=0,0,IF(AND($C$6>24,$C$6<=36),(D48*$S$6),IF($C$6>36,D48*$S$6,0))))
      #E55 =E54*C13/12
      #=IF(E23=1,PV($C$15/12,24,,-E53,1),IF($C$6<25,0,PV($C$15/12,24,,-$E$55,1))
      bd = {
          :sum => 0.0
      }
      0.upto(11) do |month|
        period = ( (store * 12.0) - 12.0 + month )
        if @free_rent_interval.include?((period + 1).to_i)
          #PV($C$15/12,24,,-E53,1)
          bd[period] = (period >= @term_months) ? 0.00 : present_value(@ll_expenses_for_less_than_12[month+1], period)
        else
          #PV($C$15/12,24,,-$E$55,1)
          bd[period] = (period >= @term_months) ? 0.00 : present_value(monthly_average - @ll_expenses_for_less_than_12[month+1], period)
        end
        if month == 0 && store == 1
          bd[period] += improvement_and_commission
          bd[period] -= @additional_ll_allowance * @rentable_sf
        end
        bd[:sum] += bd[period]
      end
      bd
    end

    def breakdown_for_ll_with_discount(store, expense, without_rent_expense, improvement_and_commission)
      total_after_delay_start_discount = expense
      expense_after_delay_start_discount = without_rent_expense

      bd = {
          :sum => 0.0
      }
      0.upto(11) do |month|
        total_after_delay_start_discount = total_after_delay_start_discount - ( @delay_start_discount[(store * 12)-12+month+1].present? ? @delay_start_discount[(store * 12)-12+month+1] : 0 )
        total_after_delay_start_discount -= (@tenant_ti * @rentable_sf) if (month == 0 && store == 1)
        total_after_delay_start_discount -= (@additional_ll_allowance * @rentable_sf) if (month == 0 && store == 1)
        expense_after_delay_start_discount = expense_after_delay_start_discount - ( @delay_start_discount[(store * 12)-12+month+1].present? ? @delay_start_discount[(store * 12)-12+month+1] : 0 )
        period = ( (store * 12.0) - 12.0 + month )
        if @free_rent_interval.include?((period + 1).to_i)
          #PV($C$15/12,24,,-E53,1)
          bd[period] = (period >= @term_months) ? 0.00 : present_value(expense_after_delay_start_discount, period)
        else
          #PV($C$15/12,24,,-$E$55,1)
          bd[period] = (period >= @term_months) ? 0.00 : present_value(total_after_delay_start_discount, period)
        end
        if month == 0 && store == 1
          bd[period] += improvement_and_commission
        end
        bd[:sum] += bd[period]
        total_after_delay_start_discount = expense
        expense_after_delay_start_discount = without_rent_expense
      end
      bd
    end

    def breakdown_for_ll_with_discount_with_interest(store, rent_after_expense, expense, commission, improvement_additional_ll_allowence)

      rent_after_delay_start_discount = rent_after_expense
      expense_after_delay_start_discount = expense

      bd = {
          :sum => 0.0
      }
      0.upto(11) do |month|

        rent_after_delay_start_discount = rent_after_delay_start_discount - ( @delay_start_discount_for_term_greater_12[(store * 12)-12+month+1].present? ? @delay_start_discount_for_term_greater_12[(store * 12)-12+month+1] : 0 )
        expense_after_delay_start_discount = expense_after_delay_start_discount - ( @delay_start_discount_for_term_greater_12[(store * 12)-12+month+1].present? ? @delay_start_discount_for_term_greater_12[(store * 12)-12+month+1] : 0 )
        if @interest_rate == 0.0 && (month > 0 || store > 1)
          improvement_additional_ll_allowence = 0.0
        end
        period = ( (store * 12.0) - 12.0 + month )
        if @free_rent_interval.include?((period + 1).to_i)
          #PV($C$15/12,24,,-E53,1)
          bd[period] = (period >= @term_months) ? 0.00 : present_value(expense_after_delay_start_discount + improvement_additional_ll_allowence, period)
        else
          #PV($C$15/12,24,,-$E$55,1)
          bd[period] = (period >= @term_months) ? 0.00 : present_value(rent_after_delay_start_discount + improvement_additional_ll_allowence, period)
        end
        bd[period] += commission if(month == 0 && store == 1)
        bd[:sum] += bd[period]
        rent_after_delay_start_discount = rent_after_expense
        expense_after_delay_start_discount = expense

      end
      bd
    end

    def breakdown_for_ll_with_discount_with_interest_less_than_12(store, rent_after_expense, commission, improvement_additional_ll_allowence)
      expense = 0
      rent_after_delay_start_discount = rent_after_expense
      expense_after_delay_start_discount = expense

      bd = {
          :sum => 0.0
      }
      0.upto(11) do |month|

        rent_after_delay_start_discount = rent_after_delay_start_discount - ( @ll_expenses_for_less_than_12[(store * 12)-12+month+1].present? ? @ll_expenses_for_less_than_12[(store * 12)-12+month+1] : 0 )
        expense_after_delay_start_discount = expense_after_delay_start_discount - ( @ll_expenses_for_less_than_12[(store * 12)-12+month+1].present? ? @ll_expenses_for_less_than_12[(store * 12)-12+month+1] : 0 )
        if @interest_rate == 0.0 && (month > 0 || store > 1)
          improvement_additional_ll_allowence = 0.0
        end
        period = ( (store * 12.0) - 12.0 + month )
        if @free_rent_interval.include?((period + 1).to_i)
          #PV($C$15/12,24,,-E53,1)
          bd[period] = (period >= @term_months) ? 0.00 : present_value(expense_after_delay_start_discount + improvement_additional_ll_allowence, period)
        else
          #PV($C$15/12,24,,-$E$55,1)
          bd[period] = (period >= @term_months) ? 0.00 : present_value(rent_after_delay_start_discount + improvement_additional_ll_allowence, period)
        end
        bd[period] += commission if(month == 0 && store == 1)
        bd[:sum] += bd[period]
        rent_after_delay_start_discount = rent_after_expense
        expense_after_delay_start_discount = expense

      end
      bd
    end

    def breakdown_for_ll_with_discount_with_interest_pv_annual_income_average_less_than_12(store, rent_after_expense, commission, improvement_additional_ll_allowence)
      expense = 0.0
      rent_after_delay_start_discount = rent_after_expense
      expense_after_delay_start_discount = expense

      bd = {
          :sum => 0.0
      }
      0.upto(11) do |month|

        rent_after_delay_start_discount = rent_after_delay_start_discount - ( @ll_expenses_for_less_than_12[(store * 12)-12+month+1].present? ? @ll_expenses_for_less_than_12[(store * 12)-12+month+1] : 0 )
        expense_after_delay_start_discount = expense_after_delay_start_discount - ( @ll_expenses_for_less_than_12[(store * 12)-12+month+1].present? ? @ll_expenses_for_less_than_12[(store * 12)-12+month+1] : 0 )
        if @interest_rate == 0.0 && (month > 0 || store > 1)
          improvement_additional_ll_allowence = 0.0
        end
        period = ( (store * 12.0) - 12.0 + month )
        if @free_rent_interval.include?((period + 1).to_i)
          #PV($C$15/12,24,,-E53,1)
          bd[period] = present_value(expense_after_delay_start_discount + improvement_additional_ll_allowence, period)
        else
          #PV($C$15/12,24,,-$E$55,1)
          bd[period] = (period >= @term_months) ? present_value(rent_after_delay_start_discount, period) : present_value(rent_after_delay_start_discount + improvement_additional_ll_allowence, period)
        end
        bd[period] += commission if(month == 0 && store == 1)
        bd[:sum] += bd[period]
        rent_after_delay_start_discount = rent_after_expense
        expense_after_delay_start_discount = expense

      end
      bd
    end

    def breakdown_for_ll_total_income(store, rent_after_expense, expense, commission, improvement_additional_ll_allowence)

      rent_after_delay_start_discount = rent_after_expense
      expense_after_delay_start_discount = expense

      bd = {
          :sum => 0.0
      }
      0.upto(11) do |month|

        rent_after_delay_start_discount = rent_after_delay_start_discount - ( @delay_start_discount_for_term_greater_12[(store * 12)-12+month+1].present? ? @delay_start_discount_for_term_greater_12[(store * 12)-12+month+1] : 0 )
        expense_after_delay_start_discount = expense_after_delay_start_discount - ( @delay_start_discount_for_term_greater_12[(store * 12)-12+month+1].present? ? @delay_start_discount_for_term_greater_12[(store * 12)-12+month+1] : 0 )
        if @interest_rate == 0.0 && (month > 0 || store > 1)
          improvement_additional_ll_allowence = 0.0
        end
        period = ( (store * 12.0) - 12.0 + month )
        if @free_rent_interval.include?((period + 1).to_i)
          #PV($C$15/12,24,,-E53,1)
          bd[period] = (period >= @term_months) ? 0.00 : (expense_after_delay_start_discount + improvement_additional_ll_allowence)
        else
          #PV($C$15/12,24,,-$E$55,1)
          bd[period] = (period >= @term_months) ? 0.00 : (rent_after_delay_start_discount + improvement_additional_ll_allowence)
        end
        bd[period] += commission if(month == 0 && store == 1)
        bd[:sum] += bd[period]
        rent_after_delay_start_discount = rent_after_expense
        expense_after_delay_start_discount = expense

      end
      bd
    end

    def breakdown_for_ll_total_income_less_than_12(store, rent_after_expense, commission, improvement_additional_ll_allowence)
      expense = 0
      rent_after_delay_start_discount = rent_after_expense
      expense_after_delay_start_discount = expense

      bd = {
          :sum => 0.0
      }
      0.upto(11) do |month|

        rent_after_delay_start_discount = rent_after_delay_start_discount - ( @ll_expenses_for_less_than_12[(store * 12)-12+month+1].present? ? @ll_expenses_for_less_than_12[(store * 12)-12+month+1] : 0 )
        expense_after_delay_start_discount = expense_after_delay_start_discount - ( @ll_expenses_for_less_than_12[(store * 12)-12+month+1].present? ? @ll_expenses_for_less_than_12[(store * 12)-12+month+1] : 0 )
        if @interest_rate == 0.0 && (month > 0 || store > 1)
          improvement_additional_ll_allowence = 0.0
        end
        period = ( (store * 12.0) - 12.0 + month )
        if @free_rent_interval.include?((period + 1).to_i)
          #PV($C$15/12,24,,-E53,1)
          bd[period] = (period >= @term_months) ? 0.00 : (expense_after_delay_start_discount + improvement_additional_ll_allowence)
        else
          #PV($C$15/12,24,,-$E$55,1)
          bd[period] = (period >= @term_months) ? 0.00 : (rent_after_delay_start_discount + improvement_additional_ll_allowence)
        end
        bd[period] += commission if(month == 0 && store == 1)
        bd[:sum] += bd[period]
        rent_after_delay_start_discount = rent_after_expense
        expense_after_delay_start_discount = expense

      end
      bd
    end

    def pv_breakdown(store, expense, without_rent_expense)
      total_after_delay_start_discount = expense
      expense_after_delay_start_discount = without_rent_expense
      bd = {
          :sum => 0.0
      }
      0.upto(11) do |month|
        period = ( (store * 12.0) - 12.0 + month )
        total_after_delay_start_discount = total_after_delay_start_discount - ( @delay_start_discount[(store * 12)-12+month+1].present? ? @delay_start_discount[(store * 12)-12+month+1] : 0 )
        expense_after_delay_start_discount = expense_after_delay_start_discount - ( @delay_start_discount[(store * 12)-12+month+1].present? ? @delay_start_discount[(store * 12)-12+month+1] : 0 )
        if @free_rent_interval.include?((period + 1).to_i)
          bd[period] = present_value(expense_after_delay_start_discount, period)
        else
          bd[period] = present_value(total_after_delay_start_discount, period)
        end
        bd[:sum] += bd[period]
        total_after_delay_start_discount = expense
        expense_after_delay_start_discount = without_rent_expense
      end
      bd
    end

    def pv_annual_income_average(store, monthly_average, total_expense)
      bd = {
          :sum => 0.0
      }
      0.upto(11) do |month|
        period = ( (store * 12.0) - 12.0 + month )
        if @free_rent_interval.include?((period + 1).to_i)
          bd[period] = present_value(0, period)
        else
          bd[period] = present_value(monthly_average, period)
        end
        bd[:sum] += bd[period]
        if month == 0
          bd[:sum] += total_expense
        end
      end
      bd
    end

    def pv_ll_income_less_than_12(store, monthly_average, total_expense)
      bd = {
          :sum => 0.0
      }
      0.upto(11) do |month|
        period = ( (store * 12.0) - 12.0 + month )
        if @free_rent_interval.include?((period + 1).to_i)
          #PV($C$15/12,24,,-E53,1)
          bd[period] = (period >= @term_months) ? 0.00 : present_value(0, period)
        else
          #PV($C$15/12,24,,-$E$55,1)
          bd[period] = (period >= @term_months) ? 0.00 : present_value(monthly_average, period)
        end
        bd[:sum] += bd[period]
        if month == 0
          bd[:sum] += total_expense
        end
      end
      bd
    end

    def prorate(store, period)
      num_full_years = (@term_months / 12.0).floor
      return 1 if period <= num_full_years
      (1.0 - (((period * 12.0) - @term_months) / 12.0))
    end

    def match_commencement(date)
      begin
        date = Date.parse(date) if date.is_a? String
        (@commencement.month == date.month and @commencement.year == date.year)
      rescue Exception => e
        Rails.logger.error [e.inspect, e.message, e.backtrace.join("\n")].join("\n")
        false
      end
    end

    # Can be blank or have a value, if it's blank, then it's lease_commencement + 1 as start date
    def uses_start_date?(datatype)
      @expenses[datatype].has_key? :calculation_type and
        @expenses[datatype][:calculation_type].include? 'with_start_and_base_year' and
        @expenses[datatype].has_key? :start_date and
        (@expenses[datatype][:start_date].blank? or !match_commencement(@expenses[datatype][:start_date]))
    end

    def free_rent_costs(store, period)
      # cost per month * number of months free in year
      #free_rent_per_month(store, period) * @free_rent
      #
      #=IF(C35=0,0,C20*$C$13/12+C8*$C$13/12)
      # if free_rent = 0 ? 0 : pre_free_rent*@rentable_sf/12 + @base_rent * @rentable_sf / 12
      free_rent_costs = 0.0
      free_months = free_rent_months(store,period)
      if (free_months > 0)
        free_rent_per_month(store,period)
      end
      free_rent_costs
    end

    def free_rent_per_month(store, period)
      #if period == 1
      #  (@results[store][:tenant_costs_per_year][:pre_free_rent] + @results[store][:tenant_costs_per_year][:base_rent_increase]) * @rentable_sf / 12.0
      #else
      #  0
      #end
      if @is_base_rent
        if @term_months < 12
          (pre_free_rent(1,1,1) + @results[store][:tenant_costs_per_year][:non_prorated_base_rent_increase]) * @rentable_sf / @term_months.to_f
        else
          (pre_free_rent(1,1,1) + @results[store][:tenant_costs_per_year][:non_prorated_base_rent_increase]) * @rentable_sf / 12.0
        end
      else
        (pre_free_rent(store,period,1) + @results[store][:tenant_costs_per_year][:non_prorated_base_rent_increase]) * @rentable_sf / 12.0
      end
    end

    def process_free_rent_interval(interval, free_rent_type)
      if free_rent_type == 'consecutive'
        interval = '1-'+interval
      end
      months = []
      interval.split(',').each do |t|
        first, last = t.split('-').map(&:to_i)
        unless first == 0
          if last.nil?
            months.concat([first])
          else
            while (first <= last)
              months.concat([first])
              first += 1
            end
          end
        end
      end
      @free_rent = months.length
      months
    end
  end # End Class

end # End Module
