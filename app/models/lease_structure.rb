class LeaseStructure < ActiveRecord::Base
  belongs_to :office
  has_many :lease_structure_expenses, dependent: :destroy
  has_many :tenant_record_imports
  before_validation :check_name_uniqueness, :default_values

  validates_associated :office
  validates :name, presence: true, allow_nil: false
  validates :discount_rate, presence: true, allow_nil: false, numericality: {:greater_than_equal_to => 0, :less_than_equal_to => 100 }
  validates :interest_rate, presence: true, allow_nil: false, numericality: {:greater_than_equal_to => 0, :less_than_equal_to => 100 }

  accepts_nested_attributes_for :lease_structure_expenses

  # attr_accessible :name, :description, :discount_rate, :interest_rate, :lease_structure_expenses_attributes

  def default_values
    self.discount_rate ||= 0.0
    self.interest_rate ||= 0.0
  end

  def expenses
    lease_structure_expenses
  end

  def check_name_uniqueness
    # using this method to check because this ", uniqueness: { :scope => [:account_id] }"
    # doesn't catch global and account scoped uniqueness of name
    found = LeaseStructure.where(:name => name, :office_id => [nil, office_id]).map(&:id)
    if not id.nil? # not new remove self from unique check
      found.delete(id)
    end
    errors.add(:name, "already exists, choose a different name.") if found.count > 0
  end

  def import_mapping
    {
        "lease_structure_name_#{self.id}" => {
            :spreadsheet_column => "lease_structure",
            :default_value => self.name,
            :record_column => "leasestructure_name"
        },
        "lease_structure_description_#{self.id}" => {
            :spreadsheet_column => "lease_structure_description",
            :default_value => self.description,
            :record_column => "leasestructure_description"
        },
        "lease_structure_discount_rate_#{self.id}" => {
            :spreadsheet_column => "discount_rate",
            :default_value => self.discount_rate,
            :record_column => "leasestructure_discount_rate"
        },
        "lease_structure_interest_rate_#{self.id}" => {
            :spreadsheet_column => "interest_rate",
            :default_value => self.interest_rate,
            :record_column => "leasestructure_interest_rate"
        }
    }
  end

  def self.default_lease_structure lease_structure, is_predefined_ls = true
    flag = true
    if is_predefined_ls
      ls = self.where(lease_structure.except(:lease_structure_expenses_attributes))
      ls = ls.first if ls.present?
      begin
        unless ls.blank?
          # handles the scenario when lease_structure_expenses_attributes neither present in params nor database
          if lease_structure[:lease_structure_expenses_attributes].present? || ls.lease_structure_expenses.present?
            flag =  (lease_structure[:lease_structure_expenses_attributes].present? &&
                ls.lease_structure_expenses.present? &&
                lease_structure[:lease_structure_expenses_attributes].count == ls.lease_structure_expenses.count)
            if flag
              lease_structure[:lease_structure_expenses_attributes].each do |key, hash|
                hash[:start_date] = nil if hash.include?(:start_date) && hash[:start_date].blank?
                hash[:delay_start_date] = nil if hash.include?(:delay_start_date) && hash[:delay_start_date].blank?
                #hash[:name] = Expense.where('name like ?', "#{hash[:name]}%").first.name rescue hash[:name]
                hash[:default_cost] = hash[:default_cost].to_f
                hash[:increase_percent] = hash[:increase_percent].to_f
                flag = false unless ls.lease_structure_expenses.where(hash).present?
              end
            end
          end
        else
          flag = false
        end
      rescue => exception
        flag = nil
      end
    end
    flag
  end

  def self.update_lease_structure lease_structure
    flag = true
    ls = self.find(lease_structure[:id])

    if ls.update_attributes(lease_structure.except(:lease_structure_expenses_attributes, :lease_structure_name))
      begin
        current_hash_keys = []
        if lease_structure[:lease_structure_expenses_attributes].present?
          lease_structure[:lease_structure_expenses_attributes].each do |key, hash|
            hash[:start_date] = nil if hash.include?(:start_date) && hash[:start_date].blank?
            ls_expense = ls.lease_structure_expenses.find(key.to_i).update_attributes(hash) rescue nil
            lse = ls.lease_structure_expenses.create(hash) if ls_expense.nil?
            current_hash_keys << (ls_expense.nil? ? lse.id : key.to_i)
          end
        end
        # delete the extra lease_structure_expenses_attributes from database other than currently entered in app
        if lease_structure[:lease_structure_expenses_attributes].present? || ls.lease_structure_expenses.count > 0
          if lease_structure[:lease_structure_expenses_attributes].present?
            ls.lease_structure_expenses.each do |expense|
              unless current_hash_keys.include?(expense.id)
                expense.destroy
              end
            end
          else
            ls.lease_structure_expenses.destroy_all
          end
        end
      rescue => exception
        flag = false
      end
    else
      flag = false
    end
    flag
  end
end
