class DatabaseBackEndsController < ApplicationController
  def index
  @custom_records = CustomRecord.where('user_id = ?', @current_user.id)
  end
end
