class ApplicationController < ActionController::Base

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  before_action :configure_permitted_parameters, if: :devise_controller?

  layout  :resolve_layout

  helper SiteHelper


   protected

   def configure_permitted_parameters
     devise_parameter_sanitizer.permit(:sign_up, keys: [:first_name, :last_name, :email, :password, :password_confirmation, :avatar])
   end


  private

    def resolve_layout
      actions = [] #['common/index']
      if actions.include? "#{controller_name}/#{action_name}"
         "contained"
      else
         "application"
      end
    end

    def after_sign_in_path_for(resource)

      sign_in_url = new_user_session_url

      if session[:previous_url]
        session[:previous_url]
        session.delete(:previous_url)
      elsif request.referer == sign_in_url
        super
      else
        stored_location_for(resource) || request.referer || root_path
      end

    end



end
