class FlagedCompsController < ApplicationController
  def create
    @f_comp = FlagedComp.new
    @f_comp.user_id = current_user.id
    @f_comp.comp_id= params[:id]
    @f_comp.comp_type= params[:type]
    @f_comp.save
    if @f_comp.comp_type == 'lease'
      lease_comp = TenantRecord.find_by_id(@f_comp.id)
      user = lease_comp.user
      user_setting = UserSetting.find_by_user_id(user.id)
      user_setting.rating = 1
      if user_setting.rating == 1
        user_setting.rating = 2
        user_setting.save!
      end
      user_setting.save!
    elsif @f_comp.comp_type == 'sale'
      sale_comp = SaleRecord.find_by_id(@f_comp.id)
      user = sale_comp.user
      user_setting = UserSetting.find_by_user_id(user.id)
      user_setting.rating = 1
      if user_setting.rating == 1
        user_setting.rating = 2
        user_setting.save!
      end
      user_setting.save!
    elsif @f_comp.comp_type == 'sale'
      custom_comp = CustomRecord.find_by_id(@f_comp.id)
      user = custom_comp.user
      user_setting = UserSetting.find_by_user_id(user.id)
      user_setting.rating = 1
      if user_setting.rating == 1
        user_setting.rating = 2
        user_setting.save!
      end
      user_setting.save!
    else
      return
    end

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
