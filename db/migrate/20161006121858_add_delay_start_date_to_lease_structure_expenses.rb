class AddDelayStartDateToLeaseStructureExpenses < ActiveRecord::Migration
  def change
    add_column :lease_structure_expenses, :delay_start_date, :date
  end
end
