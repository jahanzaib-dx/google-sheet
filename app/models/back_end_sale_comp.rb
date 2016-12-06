class BackEndSaleComp < ActiveRecord::Base
  belongs_to :user
  attr_accessor :image
  def self.save_file(upload)

    file_name = upload[:image].original_filename  if  (upload[:image] !='')
    file = upload[:image].read
    file_type = file_name.split('.').last
    new_name_file = Time.now.to_i
    name_folder = new_name_file
    new_file_name_with_type = "#{new_name_file}." + file_type
    image_root = "#{Rails.root}/public/back_end_sale_comp/"
    Dir.mkdir(image_root + "#{name_folder}");
    File.open(image_root + "#{name_folder}/" + new_file_name_with_type, "wb")  do |f|
      f.write(file)
    end
    return "#{image_root}#{new_file_name_with_type}"

  end
end
