class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  
  has_many :activity_log
  has_one :account
  has_one :back_end_lease_comp
  has_one :back_end_sale_comp

  has_one :settings, class_name: 'UserSetting'


  has_many :connections
  has_many :connected_to, through: :connections, foreign_key: :agent_id
  has_many :inverse_connections, class_name: 'Connection', foreign_key: 'agent_id'
  has_many :inverse_connected_to, through: :inverse_connections, source: :user



  def all_connections
    connected_to + inverse_connected_to
  end




  has_many :connection_requests_sent, class_name: 'ConnectionRequest', foreign_key: :user_id
  has_many :connection_requests_received, class_name: 'ConnectionRequest', foreign_key: :agent_id


  #has_many :comp_requests
  has_many :outgoing_comp_requests, class_name: 'CompRequest', foreign_key: :initiator_id
  has_many :incoming_comp_requests, class_name: 'CompRequest', foreign_key: :receiver_id

  scope :outgoing_comp_requests_type, ->(user,comp_type) { joins(:outgoing_comp_requests).where("initiator_id = #{user.id} and comp_type = '#{comp_type}'", user.id, comp_type ) }
  scope :incoming_comp_requests_type, ->(user,comp_type) { joins(:incoming_comp_requests).where("receiver_id = #{user.id} and comp_type = '#{comp_type}'", user.id, comp_type ) }

  #connection request to user model by the specified user
  scope :connection_request_by_current_user, ->(user_id) { joins(:connection_requests_received).where("user_id = #{User.current_user.id} and agent_id = #{user_id}", User.current_user.id, user_id ) }

  #connection request by user model to the specified user
  scope :connection_request_to_current_user, ->(user_id) { joins(:connection_requests_sent).where("user_id = #{user_id} and agent_id = #{User.current_user.id}", user_id, User.current_user.id ) }


  has_many :sent_messages, class_name: 'Message', foreign_key: :sender_id
  has_many :received_messages, class_name: 'Message', foreign_key: :receiver_id
  has_many :unread_received_messages, -> { where status: false }, class_name: 'Message', foreign_key: :receiver_id

  # Association for sub-user

  has_many :children, class_name: 'User', :foreign_key => 'parent_id'
  belongs_to :parent, class_name: 'User', :foreign_key => 'parent_id'
  has_many :schedule_accesses, inverse_of: :user , :dependent => :destroy
  accepts_nested_attributes_for :schedule_accesses

  has_many :flaged_comps, inverse_of: :user, :dependent => :destroy

  # end sub-user

  has_many :tenant_records


  has_many :groups_owned, class_name: 'Group', foreign_key: :user_id


  has_many :memberships, foreign_key: :member_id, :dependent => :destroy
  has_many :groups_joined, :through => :memberships, source: :group



  def self.marketrex_user_id field_name
    "hex_to_int ( substring(md5(#{field_name}::text),0,2) || substring(md5(#{field_name}::text),10,2) || substring(md5(#{field_name}::text),20,2) )"
  end


  after_create :assign_default_settings, :create_account



  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable, :confirmable, :omniauthable
  
  ###has_attached_file :photo, :styles => { :medium => "300x300>", :thumb => "100x100>" }
	
	mount_uploader :avatar, AvatarUploader
  
  #:email #system is validating itself

  validates_uniqueness_of :email


  validates :first_name, presence: true, :on => :create
  validates :last_name, presence: true, :on => :create
  
  validates :email, presence: true
  validates :first_name, presence: true, :on => :update
  validates :last_name, presence: true, :on => :update
  # validates :firm_name, presence: true, :on => :update
  # validates :address, presence: true, :on => :update
  # validates :city, presence: true, :on => :update
  # validates :state, presence: true, :on => :update
  # validates :zip, presence: true, :on => :update


  def location
    if city.blank?
        state
    elsif state.blank?
        city
    else
        "#{city}, #{state}"
    end
  end

  def name
    unless first_name.blank?
      "#{first_name} #{last_name}"
    else
      "<#{email}>"
    end
  end

  def can_send_requests?
    return true
    #!mobile.nil?  and mobile_active
  end
  
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
		
		user.password  = (0...8).map { (65 + rand(26)).chr }.join
		
		user.first_name  = auth.info.first_name
    user.last_name  = auth.info.last_name
    user.linkedin_photo = auth.info.image

		##user.username = auth.info.nickname || auth.info.email[0..(data.email.index('@') - 1)]
		
		user.skip_confirmation!
		
		user.save(validate: false)
		##user
		
		##---welcome email with random password-------------
		DxMailer.welcome_email(user).deliver
		
		####user.skip_confirmation! if user.respond_to?(:skip_confirmation)
		return user
		
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

  ## in order to access current_user variable in model files
  def self.current_user
    Thread.current[:user]
  end

  def self.current_user=(user)
    Thread.current[:user] = user
  end
  ## -------------------------

  def create_account
    role = get_role
    values = {:user_id => self.id, :fullname => "#{self.first_name} #{self.last_name}", :role =>"#{role}"}
    Account.create(values)
  end

  def create_schedule_access
    values = {:user_id => self.id, :start_date_time => self.start_date_time, :end_date_time => self.end_date_time}
    ScheduleAccess.create(values)
  end

  def self.search(email, name, firm)
      if !name.blank? || !email.blank? || !firm.blank?
        user = User.joins(:account)
        user = user.where.not('role = ?', 'admin')
        user = user.where('first_name iLIKE ? OR last_name iLIKE ? ',"%#{name}%","%#{name}%") unless name.blank?
        user = user.where('email iLIKE ?' ,"%#{email}%") unless email.blank?
        user
      end
  end

  def get_role
    return ( self.parent_id ) ? 'sub-user' : 'user'
  end

  def has_trex_admin?
    account.access('trex_admin')
  end


#####end of class#############
end
