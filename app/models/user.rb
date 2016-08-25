class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  
  has_many :activity_log

  has_one :settings, class_name: 'UserSetting'


  has_many :connections
  has_many :connected_to, through: :connections, foreign_key: :agent_id
  has_many :inverse_connections, class_name: 'Connection', foreign_key: 'agent_id'
  has_many :inverse_connected_to, through: :inverse_connections, source: :user

  def all_connections
    connected_to << inverse_connected_to
  end



  has_many :connection_requests_sent, class_name: 'ConnectionRequest', foreign_key: :user_id
  has_many :connection_requests_received, class_name: 'ConnectionRequest', foreign_key: :agent_id


  has_many :comp_requests
  has_many :outgoing_comp_requests, through: :comp_requests, foreign_key: :initiator_id
  has_many :incomming_comp_requests, through: :comp_requests, foreign_key: :receiver_id


  has_many :sent_messages, class_name: 'Message', foreign_key: :sender_id
  has_many :received_messages, class_name: 'Message', foreign_key: :receiver_id
  has_many :unread_received_messages, -> { where status: false }, class_name: 'Message', foreign_key: :receiver_id








  after_create :assign_default_settings

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable, :confirmable, :omniauthable
  
  ###has_attached_file :photo, :styles => { :medium => "300x300>", :thumb => "100x100>" }
	
	mount_uploader :avatar, AvatarUploader
  
  #:email #system is validating itself
  
  ##validates_uniqueness_of :username
  
  validates :email, presence: true
  ##validates :username, presence: true
  ##validates :mobile, presence: true
  validates :first_name, presence: true, :on => :update
  validates :last_name, presence: true, :on => :update
  validates :firm_name, presence: true, :on => :update
  validates :address, presence: true, :on => :update
  validates :city, presence: true, :on => :update
  validates :state, presence: true, :on => :update
  validates :zip, presence: true, :on => :update
  
  ##validates :mobile , :email , :username , :first_name , :last_name , :firm , :address , :city , :state , :zip
  
  ##validates :mobile, phone: { possible: false, allow_blank: true, types: [:mobile] }
  
  # -------------Setup accessible (or protected) attributes for your model ---------------
  #attr_accessible :email, :password, :password_confirmation, :remember_me, :username, :mobile, :provider, :uid, :sms_code, :mobile_active , :first_name , :last_name , :title , :firm_name , :address , :city , :state , :zip , :website , :photo , :avatar
  
  # attr_accessible :title, :body

  
  def self.connect_to_linkedin(auth, signed_in_resource=nil)
    user = User.where(:provider => auth.provider, :uid => auth.uid).first
    if user
      return user
    else
      registered_user = User.where(:email => auth.info.email).first
      if registered_user
        return registered_user
      else

##http://stackoverflow.com/questions/30211460/linkedin-oauth-exception-scope-not-authorized-r-fullprofile

        ###user = User.create(name:auth.info.first_name,
		##first_name: auth.extra.raw_info.name,
		##username: auth.info.nickname || auth.uid
		
		user = User.new
		user.provider  = auth.provider
		user.uid  = auth.provider
		user.email  = auth.info.email
		user.password  = Devise.friendly_token[0,20]
		user.first_name  = auth.info.first_name
		user.username = auth.info.nickname || auth.info.email[0..(data.email.index('@') - 1)]
		user.save(validate: false)
		
		
		
		#user = User.create(
        #                    provider:auth.provider,
        #                    uid:auth.uid,
        #                    email:auth.info.email,
        #                    password:Devise.friendly_token[0,20],
		#					username:'testing',
		#					mobile:'563256325',
        #                  )
		
      end

    end
  end
  
  ##--------------------------------
  
  def needs_mobile_number_verifying?
    if mobile_active
      return false
    end
    if mobile.empty?
      return false
    end
    return true
  end
  
  ##--------------------------------
  
  def this_is_required
    self.this_required
  end
  
  def user_connections111
  	registered_user = User.where(:email => auth.info.email).first
  end


  def assign_default_settings
    values = {:user_id => self.id, :sms => true, :email => true, :outofnetwork => false}
	settings = UserSetting.create(values)

  end

#####end of class#############
end
