class Group < ActiveRecord::Base
  belongs_to :user

  has_many :group_members
  accepts_nested_attributes_for :group_members

  scope :of_particular_user, ->(user_id) { where("user_id = #{user_id}", user_id ).all }

end
