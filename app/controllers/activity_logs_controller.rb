class ActivityLogsController < ApplicationController

  before_filter :authenticate_user!

  def index
    @activity_logs = ActivityLog.all_activities_of_user(current_user.id)
  end
end