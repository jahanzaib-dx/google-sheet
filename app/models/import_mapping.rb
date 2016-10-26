class ImportMapping < ActiveRecord::Base
  include ConditionalValidations

  belongs_to :import_template
  #attr_accessible :default_value, :spreadsheet_column, :record_column, :import_template

  conditionally_validate :record_column,
            :presence => true

  scope :lease_structures, ->{ where('record_column LIKE ?', 'leasestructure\_expenses\_%\_cost') }
  scope :calc_types, -> { where('record_column LIKE ?', 'leasestructure\_expenses\_%\_calc\_type') }
  scope :expense_default, lambda { |mapping|
    where('record_column LIKE ?', "leasestructure\\_expenses\\_%\\_#{mapping}")
  }

  def is_lease_structure?
    self[:record_column].match(/^leasestructure_expenses/)
  end

  # get matching calculation type (it is another mapping)
  def calculation_type_mapping
    return if !self.is_lease_structure?
    import_template.import_mappings.calc_types.find { |r| r.record_column == "#{self.record_column.chomp("_cost")}_calc_type" }
  end

  def lease_expense_mapping(type = 'calc_type')
    return if !self.is_lease_structure?
    import_template.import_mappings.expense_default(type.gsub('_', '\\_')).find { |r|
      r.record_column == "#{self.record_column.chomp("_cost")}_#{type}"
    }
  end

end
