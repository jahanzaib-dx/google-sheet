class AddCompTypeToFlagedComps < ActiveRecord::Migration
  def change
    add_column :flaged_comps, :comp_type, :string
  end
end
