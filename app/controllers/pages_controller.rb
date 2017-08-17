class PagesController < ApplicationController

  before_action :log_visitor , only: [:about, :plans]

  def home
    if user_signed_in?
      redirect_to dashboard_url
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

  def log_visitor
    if params[:src] == 'e'
      Visitor.create ({:page => action_name, :email => params[:e], :ip => request.remote_ip})
    end
  end


end