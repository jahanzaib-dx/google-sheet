module CompHelper

  def delfirst num1
    ##num1 = 1500
    num1str = num1.to_s
    num1length = num1str.length
    up = num1length-1
    num1.to_s[-up..-1].to_i
  end 
  
  # def sf_range num
    # inc_dec = delfirst num
    # min = num - inc_dec
    # minstr = min.to_s
    # minstrlength = minstr.length
    # minstrles1 = minstrlength-1
    # zeros = "0" * minstrles1
    # minplus = "1".concat(zeros)    
    # max = min.to_i + minplus.to_i
    # "#{min} - #{max}"
  # end
  
  def sf_range num,type='lease'
    #num = num.to_i
    range = 0
    if type == 'lease'
      if num >= 0 && num <= 3999
        range = "0-3,999"
      elsif num >= 4000 && num <= 9999
        range = "4,000-9,999"
      elsif num >= 10000 && num <= 19999
        range = "10,000-19,999"  
      elsif num >= 20000 && num <= 49000
        range = "20,000-49,000"
      elsif num > 50000
        range = "50,000+"
      end
    else  
      if num >= 0 && num <= 49000
        range = "0-49,000"
      elsif num >= 50000 && num <= 99000
        range = "50,000-99,000"
      elsif num >= 100000 && num <= 499999
        range = "100,000-499,999"  
      elsif num >= 500000 && num <= 999000
        range = "500,000-999,000"
      elsif num > 999000
        range = "1MM+"
      end
    end
  
    range
  end
  
  
  
  def comp_image comp
    
    if !comp.main_image_file_name.blank?
      
      #img = "<img src='#{comp.main_image_file_name.remove('=image("').remove('",2)') }'>"
      
      img = "<div style=\"float:right; height:40px; width: 40px; background-size:40px 40px; background-image:  
              url('#{comp.main_image_file_name.remove('=image("').remove('",2)')}');\">
             </div>"
    else
      img = "<a href='http://www.google.com/maps?cbll=#{comp.latitude},#{comp.longitude}&layer=c' target='_blank'>
              <div style=\"float:right; height:40px; width: 40px; background: #edeced 
              url('http://maps.googleapis.com/maps/api/streetview?size=50x50&location=#{comp.address1}+#{comp.city}+#{comp.state}+#{comp.zipcode}') no-repeat center;\">
              </div>
            </a>"
    end
    
    img
   
  end
  
  def large_comp_image comp
    
    if !comp.main_image_file_name.blank?
            
      img = "<div class=\"street_view_image\" style=\"background-size:336px 200px; background-image:
              url('#{comp.main_image_file_name.remove('=image("').remove('",2)')}');\">
             </div>"
             
    else
      img = "
              <div class=\"street_view_image\" style=\"background-size:336px 200px; background-image:
               url('http://maps.googleapis.com/maps/api/streetview?size=336x200&location=#{comp.address1}+#{comp.city}+#{comp.state}+#{comp.zipcode}');\">
              </div>
            "
    end
    
    img
   
  end

end

