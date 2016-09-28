class UsersController  < ApplicationController

  def dashboard
    @user = current_user
  end



  def show
	@request_id = params[:request_id]
    if @request_id
      session[:request_id] = @request_id
      session[:user_id] = params[:id]
    end

    @user = User.find(params[:id])

    unless user_signed_in?

	end

  end

  def edit

  end

  def update

  end

  def index
    if @role == 'admin'
      @users = User.search(params[:email], params[:name], params[:firm])
      @user = User.new
      @f_comps = FlagedComp.all
    else
      redirect_to '/sub_users'
    end
  end

  def sub_users
    @parent_id = ( @role == 'admin' ) ? params[:id] : current_user.id
    @subUser = User.where("parent_id = ?", @parent_id)
    @newsubUser = User.new
    @newsubUser.schedule_accesses.new
    respond_to do |format|
      format.html # sub_users.html.erb
      format.json { render json: [@subUser,@newsubUser] }
    end
  end

  def sub_users_create
    @subUser = User.new(sub_user_params)
      if @subUser.save
        flash[:success] = 'The User is successfully created!'
        redirect_to users_path
      else
        flash[:error] = @subUser.errors.full_messages
        render :action => :sub_users
      end
  end

  def sub_users_edit
    @subUser = User.find(params[:id])
    @subUser.schedule_accesses.last
    if  @role != 'admin' && @subUser.parent_id != current_user.id
      flash[:error] = 'Permission denied'
      redirect_to users_path
    end
  end

  def sub_users_update
    @subUser = User.find(params[:id])
    @subUser.schedule_accesses.last
    if  @role != 'admin' && @subUser.parent_id != current_user.id
      flash[:error] = 'Permission denied'
      redirect_to users_path
    else
      if @subUser.update(sub_user_params)
        flash[:success] = 'The User is successfully updated!'
        redirect_to users_path
      else
        flash[:error] = @subUser.errors.full_messages
        render :action => :sub_users_edit
      end
    end

  end

  def sub_users_delete
    @subUser = User.find(params[:id])
    if  @role != 'admin' && @subUser.parent_id != current_user.id
      flash[:error] = 'Permission denied'
    else
      @subUser.destroy
    end
    redirect_to users_path
  end

  private
  def sub_user_params
    params.require(:user).permit(:email, :password, :first_name , :last_name, :parent_id, :schedule_accesses_attributes => [:id, :start_date_time, :end_date_time, :status] )
  end

end