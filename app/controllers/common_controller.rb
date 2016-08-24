class CommonController < ApplicationController



  
  def index
    if user_signed_in?
      redirect_to profile_url
    else
      render "index"
    end
  end


  def dashboard
    @user = current_user
    #render "dashboard"
    render plain: @user.all_connections.count
  end
end
