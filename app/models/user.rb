class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  
  has_many :activity_log

  has_one :settings, class_name: 'UserSetting'


  has_many :connections
  has_many :connected_to, through: :connections, foreign_key: :agent_id
  has_many :inverse_connections, class_name: 'Connection', foreign_key: 'agent_id'
  has_many :inverse_connected_to, through: :inverse_connections, source: :user



  #scope :all_connections, ->() { where(:user_id => id).or.where(:agent_id => id) }
  def all_connections
    connected_to + inverse_connected_to
  end




  has_many :connection_requests_sent, class_name: 'ConnectionRequest', foreign_key: :user_id
  has_many :connection_requests_received, class_name: 'ConnectionRequest', foreign_key: :agent_id


  #has_many :comp_requests
  has_many :outgoing_comp_requests, class_name: 'CompRequest', foreign_key: :initiator_id
  has_many :incoming_comp_requests, class_name: 'CompRequest', foreign_key: :receiver_id


  has_many :sent_messages, class_name: 'Message', foreign_key: :sender_id
  has_many :received_messages, class_name: 'Message', foreign_key: :receiver_id
  has_many :unread_received_messages, -> { where status: false }, class_name: 'Message', foreign_key: :receiver_id


  has_many :tenant_records



  def self.marketrex_user_id field_name
    "hex_to_int ( substring(md5(#{field_name}::text),0,2) || substring(md5(#{field_name}::text),10,2) || substring(md5(#{field_name}::text),20,2) )"
  end


  after_create :assign_default_settings

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
  validates :firm_name, presence: true, :on => :update
  validates :address, presence: true, :on => :update
  validates :city, presence: true, :on => :update
  validates :state, presence: true, :on => :update
  validates :zip, presence: true, :on => :update


  def location
    "#{city}, #{state}"
  end

  def name
    "#{first_name} #{last_name}"
  end

  def can_send_requests?
    !mobile.nil?  and mobile_active
    return true
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

#####end of class#############
end
