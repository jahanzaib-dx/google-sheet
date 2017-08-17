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
        [ {:text => 'FAQ', :href => marketrex_faqs_path},
          {:text => 'ABOUT', :href => about_marketrex_path},
          {:text => 'CONTACT', :href => '#'},
        ]

      when 'pages/about_lease'
        [ {:text => 'FAQ', :href => leaserex_faqs_path},
          {:text => 'ABOUT', :href => about_leaserex_path},
          {:text => 'CONTACT', :href => '#'},
        ]

      when 'pages/about_tenant'
        [ {:text => 'FAQ', :href => tenantrex_faqs_path},
          {:text => 'ABOUT', :href => about_tenantrex_path},
          {:text => 'CONTACT', :href => '#'},
        ]

      when 'pages/home'
      when 'pages/plans'
      when 'sessions/new'
      when 'registrations/new'
        [ {:text => 'CONTACT', :href => '#'}]
      else
        [ {:text => 'ABOUT', :href => about_marketrex_path},
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

  def self.getComp(cid,type='lease')

    if type == 'lease'
      @comp = TenantRecord.where("id"=>cid).first
    else
      @comp = SaleRecord.where("id"=>cid).first
    end

    #unless comp.blank?
      return @comp
    #end
  end

end

