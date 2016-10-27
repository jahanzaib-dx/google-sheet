class TenantRecordImage < ActiveRecord::Base
  belongs_to :tenant_record
  has_attached_file :image, 
    styles: {edit: "200x200^", detail_page: "306"},
    :url => '/system/:class/:id/:style/:filename',
    :path => ':rails_root/public:url'
  validates_attachment_content_type :image, :content_type => /\Aimage\/.*\Z/

  # attr_accessible :image

end
