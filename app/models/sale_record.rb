class SaleRecord < ActiveRecord::Base

  scope :address_only, lambda { |office_id = nil|
    #office_scope = (!office_id.nil?) ? ", " + office_id.to_s + " as in_scope_office_id" : ""
    select("sale_records.id, zipcode, city, state, address1, 'address_only' as in_scope ")
    #.group('tenant_records.id, tenant_records.address1, tenant_records.zipcode')
  }

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
        "sale_records.id, " +

            "sale_records.address1, " +

            "sale_records.city, " +
            "sale_records.state, " +
            "sale_records.zipcode, " +
            "sale_records.zipcode_plus, " +
            "sale_records.land_size, " +

            "sale_records.latitude, " +
            "sale_records.longitude, " +

            "sale_records.view_type, " +
            #"tenant_records.office_id, " +
            #"tenant_records.team_id, " +
            #"tenant_records.data, " +

            " 0 as editable" +
            ", 'protect_view' as in_scope "
    )
    ####.joins({ :office => :firm })
    ####.group('tenant_records.id, tenant_records.address1, offices.firm_id, offices.name, offices.logo_image_file_name, firms.name')
    #.joins(:industry_sic_code)
    #.group('tenant_records.id, tenant_records.address1, offices.firm_id, offices.name, offices.logo_image_file_name, industry_sic_codes.value, industry_sic_codes.description, firms.name')
  }


end
