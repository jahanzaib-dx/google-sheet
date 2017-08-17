class Firm < ActiveRecord::Base
  acts_as_paranoid

  has_many :accounts
  has_many :offices, dependent: :destroy
  accepts_nested_attributes_for :offices
  # attr_accessible :contact_email, :contact_name, :contact_phone, :name, :offices_attributes
  #
  # validates :name, :presence => true
  # validates :contact_name, :presence => true
  # validates :contact_phone, :presence => true
  # validates :contact_email, :presence => true

end
