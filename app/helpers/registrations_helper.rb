module RegistrationsHelper
#### app/helpers/acme/registrations_helper.rb
###module Registrations::RegistrationsHelper


  def mobile_verification_button
    ###return '' unless current_user.needs_mobile_number_verifying?
    html = <<-HTML
      <!--<h3>Verify Mobile Number</h3>-->
      #{form_tag(verifications_create_path, method: "post")}
      #{button_tag('Resend verification code', type: "submit" , class: "btn btn-def btn-block tx_orange_btn")}
      </form>
    HTML
    html.html_safe
  end

 def verify_mobile_number_form
    #not empty or isset (?)
    ####return '' if current_user.sms_code?
    ###p current_user.sms_code.empty?
	###if current_user.sms_code.empty?
    html = <<-HTML
      
      #{form_tag(verifications_verify_path, method: "post" , class:"tx_form_content")}
	  
	  
	  
	  <div class="form-group input-group">
	  <h4>Enter Verification Code</h4>
      #{text_field_tag('sms_code' ,'', class: "form-control")}
	  </div>
	  
	  <div class="form-group">
      #{button_tag('Verify', type: "submit" , class: "btn btn-def btn-block tx_orange_btn")}
	  </div>
	  
      </form>
    HTML
    html.html_safe
 end

  def enter_mobile_number_form
    #not empty or isset (?)
    ####return '' if current_user.sms_code?p current_user.sms_code.empty?
    ###
    ###if current_user.sms_code.empty?
    html = <<-HTML

#{form_tag(verifications_verify_path, method: "post" , class:"tx_form_content")}



	  <div class="form-group input-group">
<br>
	  <h4>Mobile number</h4>
      #{text_field_tag('mobile' ,'', required: true, pattern: "^\+?[0-9]{1,3}-?[0-9]{6,12}$", title: 'format: +1202555012',class: "form-control")}
	  </div>

	  <div class="form-group">
      #{button_tag('save mobile number', type: "submit" , class: "btn btn-def btn-block tx_orange_btn")}
	  </div>

      </form>
    HTML
    html.html_safe
  end


  
  
end
