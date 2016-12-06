class AddNameToWhiteGloveServiceRequest < ActiveRecord::Migration
  def change
    add_column :white_glove_service_requests, :name, :string
  end
end
