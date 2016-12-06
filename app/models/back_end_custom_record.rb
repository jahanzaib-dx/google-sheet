class BackEndCustomRecord < ActiveRecord::Base
  belongs_to :user
  mount_uploader :comp_image, ImageUploader
end
