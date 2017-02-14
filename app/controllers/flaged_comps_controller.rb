class FlagedCompsController < ApplicationController
  def create
    @f_comp = FlagedComp.new
    @f_comp.user_id = current_user.id
    @f_comp.comp_id= params[:id]
    @f_comp.comp_type= params[:type]
    @f_comp.save

    respond_to do |format|
      format.json { render :json => "" }
    end

  end

  def delete
    @f_comp = FlagedComp.find(params[:id])
    @f_comp.destroy
    redirect_to users_path
  end

  def email
    @f_comp = FlagedComp.find(params[:id])
    @comps = (@f_comp.comp_type = "lease") ? TenantRecord.where('id = ?', @f_comp.comp_id).first : SaleRecord.where('id = ?', @f_comp.comp_id).first
    @user = User.find_by_id(@comps.user_id)
    DxMailer.flag_comp_email(@user,params[:message]).deliver_now
    redirect_to users_path
  end

  def delete_comp
    @f_comp = FlagedComp.where('comp_id = ?',params[:id]).all
    @comp = (@f_comp.first.comp_type = "lease") ? TenantRecord.where('id = ?', @f_comp.first.comp_id).first : SaleRecord.where('id = ?', @f_comp.first.comp_id).first
    @comp.destroy
    @f_comp.destroy_all
    redirect_to users_path
  end
end
