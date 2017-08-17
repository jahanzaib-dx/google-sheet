class ApplicationController < ActionController::Base

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  #around_filter :get_user
  before_filter :get_user, :get_role, :count_comp_request

  before_action :get_user
  before_action :configure_permitted_parameters, if: :devise_controller?

  layout  :resolve_layout

  helper SiteHelper


    def encryption (parameter)
      crypt = ActiveSupport::MessageEncryptor.new(Rails.application.secrets.secret_key_base)
      encrypted_data = crypt.encrypt_and_sign(parameter)
      decryption(encrypted_data)
    end

    def decryption (parameter)
      decrypted_back = crypt.decrypt_and_verify(parameter)
    end

   def current_user_account_type
     current_user.account.role
   end

   protected

   def configure_permitted_parameters
     devise_parameter_sanitizer.permit(:sign_up, keys: [:first_name, :last_name, :email, :password, :password_confirmation, :avatar])
   end

   def get_user
      if(user_signed_in?)
        @current_user = User.find(current_user.id)
      end
     User.current_user = @current_user
   end

  def count_comp_request
    if(user_signed_in?)
      @lease_comp_request = CompRequest.incoming_sale_lease(current_user.id,'lease')
      @sale_comp_request = CompRequest.incoming_sale_lease(current_user.id,'sale')
    end
  end

  def get_role
    if current_user
      if Account.where(:user_id => current_user.id).exists?
        @role = Account.where('user_id = ?', current_user.id).first.role
      else
        account = Account.new
        account.user_id = current_user.id
        account.fullname = "#{current_user.first_name} #{current_user.last_name}"
        account.role = 'user'
        account.save
        get_role
      end
    end
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
        ##stored_location_for(resource) || request.referer || root_path
        stored_location_for(resource) || root_path
      end

    end



end
