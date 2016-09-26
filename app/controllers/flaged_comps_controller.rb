class FlagedCompsController < ApplicationController
  def create
    @f_comp = FlagedComp.new
    @f_comp.user_id = current_user.id
    @f_comp.comp_id= params[:id]
    @f_comp.save
  end

  def delete
    @f_comp = FlagedComp.find(params[:id])
    @f_comp.destroy
    redirect_to users_path
  end

  def email
    @f_comp = FlagedComp.find(params[:id])
    @comps = TenantRecord.where('id = ?', @f_comp.comp_id).first
    @user = User.where('id = ?', @comps.user_id)
    DxMailer.flag_comp_email(@user,params[:message]).deliver_now
  end

    def delete_comp
    @f_comp = TenantRecord.find(params[:id])
    @f_comp.destroy
    redirect_to users_path
  end
end
