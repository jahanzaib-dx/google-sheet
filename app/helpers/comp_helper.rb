module CompHelper

  def delfirst num1
    ##num1 = 1500
    num1str = num1.to_s
    num1length = num1str.length
    up = num1length-1
    num1.to_s[-up..-1].to_i
  end 
  
  def sf_range num
    inc_dec = delfirst num
    min = num - inc_dec
    minstr = min.to_s
    minstrlength = minstr.length
    minstrles1 = minstrlength-1
    zeros = "0" * minstrles1
    minplus = "1".concat(zeros)    
    max = min.to_i + minplus.to_i
    "#{min} - #{max}"
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

