class Account < ActiveRecord::Base

  belongs_to :user, :dependent => :destroy
  belongs_to :firm
  belongs_to :office



  # belongs_to :market
  has_one :account_featurerails
  # has_many   :maps, :dependent => :destroy
  # has_and_belongs_to_many :teams
  # before_validation :validate_user
  #
  # attr_accessible :fullname, :role, :accepted_terms_of_service, :user_id, :firm_id, :office_id, :market_id, :team_ids
  #
  DEFAULT_ROLE = 'analyst'
  ROLES = %w[deactivated demo broker analyst office_admin firm_admin trex_admin user]
  # ACCOUNT_TYPES = %w[tenantrex cushman]
  #
  # validates :fullname, :presence => true
  # validates :role, :presence => true
  # validates :accepted_terms_of_service, :presence => true
  #
  # after_create :add_user_team
  # before_destroy :remove_user_team
  #
  # def validate_user
  #   errors.add(:user, "email address already exists") if not user.valid?
  # end
  #
  def access(access_role='deactivated')
     ROLES.index(role) >= ROLES.index(access_role)
  end
  #
  # def to_s
  #   self.fullname
  # end
  #
  # def name
  #   self.fullname
  # end
  #
  # def own_team
  #   teams.where(:name => user.email).first
  # end
  # private
  #
  # def remove_user_team
  #   self.teams.where(name: self.user.email).each(&:destroy)
  # end
  #
  # def add_user_team
  #   self.teams << Team.new(:name => self.user.email, :office_id => self.office_id, :comment => "User", :multi_user => false)
  # end
  #
end
