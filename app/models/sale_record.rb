class SaleRecord < ActiveRecord::Base

  has_one :ownership ,class_name: 'Ownership', foreign_key: :comp_id

  belongs_to :user

  mattr_accessor :sizerange

  has_many :comp_requests

  #after_destroy :cleanup
  before_destroy :cleanup
  
  def self.my_ids
    @connections = Connection.all_connection_ids(User.current_user)
    where("user_id IN (?) OR user_id=?" , @connections.to_a,User.current_user.id)
  end
  
  def self.con_ids
    @connections = Connection.all_connection_ids(User.current_user)
    where("user_id IN (?)" , @connections.to_a).
    where("address1 not in (select address1 from sale_records where user_id=?)" , User.current_user.id)
  end
  
  scope :select_extra, -> { select("
      'cp_status' as cp_status,
      'size_range' as size_range,
      'build_date_str' as build_date_str,
      'price_str' as price_str,
      'cap_rate_str' as cap_rate_str
      ") }

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
            
            "sale_records.cap_rate, " +
            "sale_records.sold_date, " +
            "sale_records.price, " +

            "sale_records.view_type, " +
            "sale_records.user_id, " +
            "sale_records.main_image_file_name, " +
            #"tenant_records.office_id, " +
            #"tenant_records.team_id, " +
            #"tenant_records.data, " +

            " 0 as editable" +
            ", 'price_str' as price_str "+
            ", 'cap_rate_str' as cap_rate_str "+
            ", 'cp_status' as cp_status "+
            ", 'land_size_str' as land_size_str "
    )
    ####.joins({ :office => :firm })
    ####.group('tenant_records.id, tenant_records.address1, offices.firm_id, offices.name, offices.logo_image_file_name, firms.name')
    #.joins(:industry_sic_code)
    #.group('tenant_records.id, tenant_records.address1, offices.firm_id, offices.name, offices.logo_image_file_name, industry_sic_codes.value, industry_sic_codes.description, firms.name')
  }
  
  #attr_accessible :is_sales_record, :land_size_identifier, :view_type,
  #                :address1, :city, :state, :land_size, :price, :cap_rate,
  #                :latitude, :longitude, :zipcode, :zipcode_plus, :office_id


  before_save :default_values
  before_validation :default_values
  
  def complete_address
    [address1, city, state, zipcode].join(", ")
  end
  
  def self.all_property_type
    arr2 = TenantRecord::SALES_PROPERTY_TYPE-['other'] 
    arr1 = select('property_type as name').my_ids.where("property_type != '' AND lower(property_type) NOT IN (?)",arr2).group('property_type').all.map{|v| v.name }
    arr = arr2 + arr1
  end

  def self.all_class_type ()
    arr2 = TenantRecord::CLASS_TYPE
    arr1 = select('class_type as name').my_ids.where("class_type != '' AND lower(class_type) NOT IN (?)",arr2).group('class_type').all.map{|v| v.name }
    arr = arr2 + arr1
    ##arr
  end

  def self.sale_sub_markets ()
    SaleRecord.select('lower(submarket) as submarket').my_ids.where("submarket is NOT NULL and submarket != ''").group('submarket').all.map{|v| v.submarket }

  end

  def self.duplicate_list user_id
    query = "
    select * FROM sale_records y
            where (select count(*) from sale_records dt
            where
              y.address1 = dt.address1 and
              y.city = dt.city and
              y.state = dt.state and
              y.submarket = dt.submarket and
              y.property_name = dt.property_name and
              y.property_type = dt.property_type and
              y.class_type = dt.class_type and
              y.land_size = dt.land_size and
              y.price = dt.price and
              y.cap_rate = dt.cap_rate and
              y.user_id=dt.user_id and
              y.user_id=#{user_id.to_s} and
              AGE(dt.sold_date , y.sold_date ) <= INTERVAL '3 months' and
              AGE(y.sold_date , dt.sold_date ) <= INTERVAL '3 months' and
              AGE(dt.build_date , y.build_date ) <= INTERVAL '3 months' and
              AGE(y.build_date , dt.build_date ) <= INTERVAL '3 months'
            ) > 1 order by y.id
    "
    SaleRecord.find_by_sql(query)
    # ActiveRecord::Base.connection.execute(query)
  end

  def na data
    begin
    if data === "Lock"
        "Lock"
    elsif data.blank? == true
      "None"
    #elsif data.delete("^0-9").to_i < 1
    #elsif data.is_a? String && data.delete("^0-9").to_i < 1
    elsif (data.is_a? Integer OR data.is_a? Float) && data < 1
      "None"
    # elsif data < 1
    #   "None"
    else
      data
    end
    rescue
      data
    end

  end

  private
  def default_values
    #puts "***********************@current user: #{User.current_user.name}"
    self.user_id ||= User.current_user.id
    self.address1 = self.address1.to_s.strip
    self.class_type = class_type.to_s.downcase
    self.view_type = view_type.to_s.downcase
    self.view_type ||= 'internal'
    self.property_type = property_type.to_s.downcase
    self.price ||= 0.00

    # this true keeps validation from failing...
    true
  end

  def self.custom_field_headers user_id
    query ="
      select  distinct header
      from (
          select skeys(custom) as header
          from sale_records
          where user_id=#{user_id}
      ) as dt"

    SaleRecord.find_by_sql(query)
  end

  def self.custom_field_values comp_id
    query ="
      select  header, value
      from (
          select skeys(custom) as header, svals(custom) as value
          from sale_records
          where id=#{comp_id}
      ) as dt"
    SaleRecord.find_by_sql(query)
  end


  def cleanup
    comp_request = CompRequest.where('comp_id = ? and comp_type = ?', self.id,"sale")
    comp_request.destroy_all if !comp_request.nil?
    activity_log = ActivityLog.where('comp_id = ? and comptype = ?', self.id,"sale")
    activity_log.destroy_all if !activity_log.nil?
    activity_log = ActivityLog.where('child_comp = ? and comptype = ?', self.id,"sale")
    activity_log.destroy_all if !activity_log.nil?
    shared_comp=SharedComp.where('comp_id = ? and comp_type = ?', self.id,"sale")
    shared_comp.destroy_all if !shared_comp.nil?
  end
end
