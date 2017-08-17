class Membership < ActiveRecord::Base

  belongs_to :group
  belongs_to :user, foreign_key: :member_id


end
