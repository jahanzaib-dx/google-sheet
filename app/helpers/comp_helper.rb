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

end

