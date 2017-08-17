module MathUtil
  def self.roundup(num)
    x = Math.log10(num).floor
    (num/(10.0 ** x)).ceil * 10 ** x
  end
end