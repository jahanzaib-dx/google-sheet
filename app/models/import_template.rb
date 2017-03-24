class ImportTemplate < ActiveRecord::Base
  include ConditionalValidations

  belongs_to :user
  has_many :import_mappings, :dependent => :destroy
  has_many :tenant_record_imports
  accepts_nested_attributes_for :import_mappings
  #attr_accessible :name, :reusable, :office, :import_mappings_attributes

  default_scope { }#where(:reusable => true) }
  scope :user_import_template, -> { unscope(:where).where reusable: [true, false] }

  conditionally_validate :name, :presence => true, allow_nil: false
  before_validation :check_name_uniqueness

  def check_name_uniqueness
    # using this method to check because this ", uniqueness: { :scope => [:account_id] }"
    # doesn't catch global and account scoped uniqueness of name
    found = ImportTemplate.where(:name => name, :user_id => [nil, user_id]).map(&:id)
    if not id.nil? # not new remove self from unique check
      found.delete(id)
    end
    errors.add(:name, "already exists, choose a different name.") if found.count > 0
  end

  def grouped_import_mappings
    {
      :name => self.name,
      :import_mappings => {
        :record_ownership     => import_mappings.map { |x| x if ['comp_type', 'contact', 'contact_email', 'contact_phone', 'view_type'].include? x[:record_column] }.compact,
        #:record_details       => import_mappings.map { |x| x if ['company', 'address1', 'suite', 'city', 'state', 'zipcode', 'location_type', 'industry_sic_code_id', 'property_name', 'submarket'].include? x[:record_column] }.compact,
        :record_details       => import_mappings.map { |x| x if ['company', 'address1', 'suite', 'city', 'state', 'zipcode', 'location_type', 'industry_type', 'property_name', 'submarket'].include? x[:record_column] }.compact,
        :property_information => import_mappings.map { |x| x if ['class_type', 'property_type', 'comments'].include? x[:record_column] }.compact,
        :lease_details        => import_mappings.map { |x| x if ['free_rent', 'lease_commencement_date', 'lease_term_months', 'lease_type', 'size', 'tenant_improvement', 'tenant_ti_cost'].include? x[:record_column] }.compact,
        :rent_details         => import_mappings.map { |x| x if ['base_rent', 'escalation'].include? x[:record_column] }.compact,
        :stepped_rents        => self.import_mappings.where('record_column like ?', 'rent_%')
      }
    }
  end


  private

  def self.inheritance_column
    nil
  end


end
