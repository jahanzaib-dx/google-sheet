class ConnectionsController < ApplicationController

  
  ##before_action : authenticate_user
  ##before_filter :authenticate_user!, except: [:index, :show]
  before_filter :authenticate_user!
  

  
  def index
 		
		##@user_connections = Connections.where(:user_id=>current_user.id)		
		
		type = 'all'
				
		if params[:ctype] == 'pending'
			type = 'pending'
		end
		
		if params[:ctype] == 'sent'
			type = 'sent'
		end
		
		##type = 'sent'
		
		@user_connections = Connection.getConnections(current_user,type);
		
		##@user_connections = Connection.joins("INNER JOIN users ON users.id = connections.con_id").select("connections.*, users.* , connections.id as cid").where(:user_id=>current_user.id)
			  
		
		render "connections"
  end
  
  def add
  
  		@user = current_user
		
		## check if mobile no verify
		if @user.mobile.nil?
			
			flash[:error] = "Please enter mobile number and verify to make connections"
			
			redirect_to profile_update_path
			return
		end
		
		if @user.mobile_active != true
			flash[:error] = "Please verify your mobile number to make connections"
			redirect_to verifications_verify_path
			return
		end
		
		
		if params[:email]
		
			con_user = User.where(:email=>params[:email]).where("email != ?" , @user.email).first
			
			if con_user
				## if already connected
				already_con = Connections.where("(user_id = #{con_user.id} and con_id = #{@user.id} ) OR (user_id = #{@user.id} and con_id = #{con_user.id}) ").first
				
				if already_con
					flash[:error] = "You are already connected to selected user"
					redirect_to connections_path
					return
				end
				
				## add connection and send email
				Connections.create(:user_id => @user.id , :con_id => con_user.id , :status => 1 , :created_at => Date.today.to_time , :message => params[:p_message])
				Connections.create(:user_id => con_user.id , :con_id => @user.id , :status => 0 , :created_at => Date.today.to_time , :message => params[:p_message])
				
				flash[:success] = "Connection request sent successfully"
			elsif
				## error if email not found
				flash[:error] = "Email doesnot exist"
			end
		
		end
		
		
		redirect_to connections_path
		
  end
  
  def ignore
  		@user = current_user
		
		if params[:cid]
			## set status to 3
			con = Connections.where(:id=>params[:cid]).first
			con.update_attributes(:status => 3 , :created_at => Date.today.to_time)
			
			con2 = Connections.where(:user_id=>con.con_id , :con_id=>con.user_id).first
			con2.update_attributes(:status => 3 , :created_at => Date.today.to_time)
		end
		
		redirect_to connections_path 
  end
  
  def accept
  		@user = current_user
		
		if params[:cid]
			## set status to 2
			con = Connections.where(:id=>params[:cid]).first
			con.update_attributes(:status => 2 , :created_at => Date.today.to_time)
			
			## insert new record of connection
			###new_con = Connections.new
			
			con2 = Connections.where(:user_id=>con.con_id , :con_id=>con.user_id).first
			con2.update_attributes(:status => 2 , :created_at => Date.today.to_time)
			
			##Connections.create(:user_id => con.con_id , :con_id => con.user_id , :status => 2 , :created_at => Date.today.to_time)
			
			flash[:success] = "Now you are connected"
		end	
  
  		redirect_to connections_path
  end
  
  
 
#########
end
