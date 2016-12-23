class CompUnlockField < ActiveRecord::Base

  belongs_to :shared_comp, foreign_key: :shared_comp_id

end
