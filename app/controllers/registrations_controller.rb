class RegistrationsController < Devise::RegistrationsController

  def new
    unless session[:visited_plan]
      redirect_to subscription_plans_url
    else
      super
    end
  end

  def create
    super
  end

  def update
    super
  end

end