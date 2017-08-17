module DashboardHelper
  def fetch_search_query search_params
    (search_params.present? and search_params[:tenant_record].present? and
        search_params[:tenant_record].has_key? :address1) ?
        search_params[:tenant_record][:q] : (search_params[:q] rescue '')
  end

  def fetch_search_address search_params
    (search_params.present? and search_params[:tenant_record].present? and
        search_params[:tenant_record].has_key? :address1) ?
        search_params[:tenant_record][:address1] : (search_params[:address1] rescue '')
  end

  def fetch_search_zipcode search_params
    (search_params.present? and search_params[:tenant_record].present? and
        search_params[:tenant_record].has_key? :zipcode) ?
        search_params[:tenant_record][:zipcode] : (search_params[:zipcode] rescue '')
  end

end
