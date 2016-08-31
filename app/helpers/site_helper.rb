module SiteHelper


  def show_colored_header?
    ['passwords', 'sessions', 'registrations'].include? controller_name
  end

  def show_dark_footer?
    ['pages'].include? controller_name
  end

  def get_footer_links
    page = "#{controller_name}/#{action_name}"

    case page
      when 'pages/about'
        [ {:text => 'FAQ', :href => '#'},
          {:text => 'ABOUT', :href => '#'},
          {:text => 'CONTACT', :href => '#'},
        ]
      when 'pages/home'
      when 'pages/plans'
      when 'sessions/new'
      when 'registrations/new'
        [ {:text => 'CONTACT', :href => '#'}]
      else
        [ {:text => 'ABOUT', :href => '#'},
          {:text => 'CONTACT', :href => '#'},
        ]
    end
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

