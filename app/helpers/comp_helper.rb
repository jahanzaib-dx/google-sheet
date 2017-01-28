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
        range = "0-3999"
      elsif num >= 4000 && num <= 9999
        range = "4000-9999"
      elsif num >= 10000 && num <= 19999
        range = "10000-19999"  
      elsif num >= 20000 && num <= 49000
        range = "20000-49000"
      elsif num > 50000
        range = "50000+"
      end
    else  
      if num >= 0 && num <= 49000
        range = "0-49000"
      elsif num >= 50000 && num <= 99000
        range = "50000-99000"
      elsif num >= 100000 && num <= 499999
        range = "100000-499999"  
      elsif num >= 500000 && num <= 999000
        range = "500000-999000"
      elsif num > 999000
        range = "1MM+"
      end
    end
  
    range
  end
  
  
  
  def comp_image comp
    
    if !comp.main_image_file_name.blank?
      
      img = "<img src='#{comp.main_image_file_name.remove('=image("').remove('",2)') }'>"
    else
      img = "<a href='http://www.google.com/maps?cbll=#{comp.latitude},#{comp.longitude}&layer=c' target='_blank'>
              <div style=\"float:right; height:40px; width: 40px; background: #edeced 
              url('http://maps.googleapis.com/maps/api/streetview?size=50x50&location=#{comp.address1}+#{comp.city}+#{comp.state}+#{comp.zipcode}') no-repeat center;\">
              </div>
            </a>"
    end
    
    img
   
  end

end

