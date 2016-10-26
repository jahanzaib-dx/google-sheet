class DropAgreements < ActiveRecord::Migration
  def change
    drop_table :agreements
  end
end
