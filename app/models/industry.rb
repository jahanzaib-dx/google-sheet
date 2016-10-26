class Industry < ActiveRecord::Base
  # attr_accessible :name

  def self.get_industy_list
    Industry.all
  end
end
