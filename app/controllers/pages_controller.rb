class PagesController < ApplicationController



  def home
    if user_signed_in?
      redirect_to profile_url
    else
      render :home
    end
  end

  def plans
    session[:visited_plan] = true
    render :plans
  end

  def about
    render :about
  end

  def faqs

  end

end