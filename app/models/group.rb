class Group < ActiveRecord::Base

  belongs_to :user


  has_many :memberships, :dependent => :destroy
  has_many :members, :through => :memberships, source: :user


  accepts_nested_attributes_for :memberships

  scope :of_particular_user, ->(user_id) { where("user_id = #{user_id}", user_id ).all }

end
