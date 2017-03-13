module ExtendedHash
  def method_missing(meth, *args, &block)
    if has_key?(meth.to_sym)
      self[meth.to_sym]
    else
      raise NoMethodError, 'undefined method #{meth} for #{self}'
    end
  end
end