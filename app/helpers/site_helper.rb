module SiteHelper


  def show_colored_header?
    ['passwords', 'sessions'].include? controller_name
  end

  def user_image(user,cssclass="")

    if FileTest.exist?("#{Rails.root}/public/uploads/user/avatar/#{user.id}/#{user.avatar}")
      image_check = image_tag("../uploads/user/avatar/#{user.id}/#{user.avatar}" , :class => "#{cssclass}")
    else
      image_check = image_tag("default-user.png" , :class => "#{cssclass}")
    end

    return image_check
  end

end

def showCompStatus(status = "")
	if status
	
		if status == "Approve"
			r = "Approved";
		elsif status == "Decline"
			r = "Decline";
		elsif status == "Lock"
			r = image_tag("lock.png" , :class => "lock_image");
		elsif status == "Unlock"
			r = image_tag("lock-un.png" , :class => "unlock_img");
		elsif status == "Partial"
			r = image_tag("un-lock.png" , :class => "partial_img");
		end
		
		return r
	end
end

def showCompData(status = "" , data)
	if status
	
		if status == "Approve"
			r = "Data";
		elsif status == "Decline"
			r = "Locked";
		elsif status == "Lock"
			r = "Locked";
		elsif status == "Unlock"
			r = "Data";
		elsif status == "Partial"
			r = "Some Data";
		end
		
		return r
	end
end