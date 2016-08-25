class PagesController < ApplicationController


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