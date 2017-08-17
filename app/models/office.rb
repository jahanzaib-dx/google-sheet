class Office < ActiveRecord::Base
  # include ConditionalValidations
  # attr_accessible :title, :body
  # acts_as_paranoid

  belongs_to :firm
  has_many :accounts



  # has_many :teams
  # has_many :tenant_records, :through => :agreements
  # has_many :tenant_record_imports
  # has_many :import_templates
  # has_many :lease_structures, :dependent => :destroy
  # has_and_belongs_to_many :agreements
  # has_attached_file :logo_image,
  #   #:styles => { :medium => "300x300>", :thumb => "100x100>" },
  #   :url => '/system/office/:id/:style/:filename',
  #   :path => ':rails_root/public:url',
  #   :default_url => "/logos/:style/missing_logo.png"
  #
  # conditionally_validate :logo_image, :attachment_content_type => { :content_type => /\Aimage\/.*\Z/ }
  #
  # before_validation {
  #   logo_image.clear if delete_logo_image == '1'
  # }
  #
  # attr_accessor :delete_logo_image
  #
  # attr_accessible :contact_email,
  #                 :contact_name,
  #                 :contact_phone,
  #                 :name,
  #                 :firm_id,
  #                 :address1,
  #                 :address2,
  #                 :city,
  #                 :state,
  #                 :zipcode,
  #                 :zipcode_plus,
  #                 :latitude,
  #                 :longitude,
  #                 :logo_image,
  #                 :registration_code,
  #                 :delete_logo_image
  #
  #
  #
  # validates_presence_of :name, :address1, :city, :state, :zipcode, :contact_name, :contact_phone, :contact_email, :firm
  #
  # #used in admin selector
  # def name_with_firm
  #   "(#{firm.name}) #{name}"
  # end
  #

end
