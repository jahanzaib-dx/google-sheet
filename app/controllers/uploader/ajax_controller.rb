class Uploader::AjaxController < ApplicationController

  def property_type_list
    @result = PropertyType.property_type_list
    render json: @result
  end

  def opex_market_list
    @result = OpexMarket.opex_market_list(params[:property_type_id])
    render json: @result
  end

  def market_expenses_list
    @result = MarketExpense.market_expenses_list(params[:opex_market_id])
    render json: @result
  end

  def opex_type_list
    @result = MarketExpense.opex_type_list
    render json: @result
  end

  def get_custom_record_attributes
    @custom_record = CustomRecord.find params[:custom_record_id]
    keys = []
    custom_record_properties = []

    @custom_record.custom_record_properties.each do |property|
      unless keys.include? property.key
        keys << property.key
        #property.key.capitalize!
        custom_record_properties << property
      end
    end

    @custom_record.custom_record_properties = custom_record_properties

    respond_to do |format|
      format.json { render json: @custom_record.to_json(include: 'custom_record_properties' ) }
      format.html { render json: @custom_record.to_json(include: 'custom_record_properties' ) }
    end
  end
end
