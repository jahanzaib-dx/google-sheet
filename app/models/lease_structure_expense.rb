class LeaseStructureExpense < ActiveRecord::Base
  belongs_to :lease_structure

  validates_presence_of :calculation_type
  validates :increase_percent,
            :numericality => { :greater_than_equal_to => 0, :less_than_equal_to => 100 }, :allow_nil => true
  validates :default_cost,
            :numericality => true, :allow_nil => true

  # attr_accessible :lease_structure, :name, :calculation_type, :default_cost, :increase_percent, :start_date, :delay_start_date

  CALCULATION_TYPES = {
    generic: "Pass Through",
    with_start_and_base_year: "Base Year and Start Date",
    pass_through_and_start_date: "Pass Through and Start Date"
  }.with_indifferent_access

  def import_mapping
    uid = self.id || SecureRandom::uuid
    {
      "lease_structure_expense_name_#{uid}" => {
        :spreadsheet_column => "#{ImportTemplateUtil.spreadsheet_columnize(self.name)}_name",
        :default_value => self.name,
        :record_column => "leasestructure_expenses_#{ImportTemplateUtil.spreadsheet_columnize(self.name)}_name"
      },
      # Import mapping puts cost with the expense name
      "lease_structure_expense_cost_#{uid}" => {
        :spreadsheet_column => "#{ImportTemplateUtil.spreadsheet_columnize(self.name)}",
        :default_value => self.default_cost,
        :record_column => "leasestructure_expenses_#{ImportTemplateUtil.spreadsheet_columnize(self.name)}_cost"
      },
      "lease_structure_expense_calc_type_#{uid}" => {
        :spreadsheet_column => "#{ImportTemplateUtil.spreadsheet_columnize(self.name)}_calculation_type",
        :default_value => self.calculation_type,
        :record_column => "leasestructure_expenses_#{ImportTemplateUtil.spreadsheet_columnize(self.name)}_calc_type"
      },
      "lease_structure_expense_increase_percent_#{uid}" => {
        :spreadsheet_column => "#{ImportTemplateUtil.spreadsheet_columnize(self.name)}_increase_percent",
        :default_value => self.increase_percent,
        :record_column => "leasestructure_expenses_#{ImportTemplateUtil.spreadsheet_columnize(self.name)}_increase_percent"
      },
      "lease_structure_expense_start_date_#{uid}" => {
        :spreadsheet_column => "#{ImportTemplateUtil.spreadsheet_columnize(self.name)}_start_date",
        :default_value => self.start_date,
        :record_column => "leasestructure_expenses_#{ImportTemplateUtil.spreadsheet_columnize(self.name)}_start_date"
      }
    }
  end

end

