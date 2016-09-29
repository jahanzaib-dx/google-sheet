class GroupsController < ApplicationController

  def index
    @connections = Connection.all_connections_of_user(current_user.id)
    @groups = current_user.groups_owned
    render :show
  end

  def show
    if params[:id].blank?
      @connections = Connection.all_connections_of_user(current_user.id)
    else
      @group = Group.where("id = #{params[:id]} and user_id = #{current_user.id}").first
    end
    @groups = current_user.groups_owned
  end

  def new
    @group = Group.new
    @group.memberships.build

    @connections = Connection.all_connections_of_user(current_user.id)

  end

  def create

    @group = Group.new({:title => params[:group][:title]})
    @group.user_id = current_user.id

    if @group.save
      params[:group][:member_ids].each do |member_id|
        Membership.new({:member_id=> member_id, :group_id => @group.id}).save
      end
      flash[:success] = "Group '#{@group.title}' added successfully"
      redirect_to groups_url(@group.id)
      return
    else
      flash[:error] = "Unable to add Group '#{@group.title}'. #{@group.errors.full_messages}"
    end

    @connections = Connection.all_connections_of_user(current_user.id)
    render :new
  end

  def edit
    @group = Group.where("id = #{params[:id]} and user_id = #{current_user.id}").first
    @connections = Connection.all_connections_of_user(current_user.id)

    render :new
  end

  def update
    @group = Group.find(params[:id])
    if @group.update_attributes({:title => params[:group][:title]})

      @group.member_ids.each do |member_id|
        unless params[:group][:member_ids].include? member_id
          Membership.where({:member_id=> member_id, :group_id => @group.id}).first.delete
        end
      end

      params[:group][:member_ids].each do |member_id|
        unless @group.member_ids.include? member_id
          Membership.new({:member_id=> member_id, :group_id => @group.id}).save
        end
      end

      redirect_to @group, notice: "Successfully updated group #{@group.title}."
    else
      render :edit
    end
  end

  def destroy


    @group = Group.where("id = #{params[:id]} and user_id = #{current_user.id}").first
    unless @group.nil?
      Membership.where({:group_id => @group.id}).delete_all
    end
    @group.delete
    
    redirect_to groups_url, notice: "Successfully deleted group #{@group.title}."

  end


  def group_params
    params.require(:group).permit(:title, :member_ids => [])
  end



end