class GroupsController < ApplicationController

  def index
    unless params[:id].blank?
      @group = Group.where("id = #{params[:id]} and user_id = #{current_user.id}").first;
    else
      @connections = Connection.all_connections_of_user(current_user.id)
    end

    @groups = current_user.groups

  end

  def new
    @group = Group.new
    @group.group_members.build

    @connections = Connection.all_connections_of_user(current_user.id)
  end

  def create

    @group = Group.new(group_params)
    @group.user_id = current_user.id
=begin

    if @group.group_members.count < 1
      flash[:error] = "Please select members before saving"
    else
=end
      if @group.save
        flash[:success] = "Group '#{@group.title}' added successfully"
        redirect_to groups_url(@group.id)
        return
      else
        flash[:error] = "Unable to add Group '#{@group.title}'. <br/>"
      end
    #end
    @connections = Connection.all_connections_of_user(current_user.id)
    render :new
  end

  def group_params
    params.require(:group).permit(:title,  :group_members_attributes => [:member_id])
  end

end