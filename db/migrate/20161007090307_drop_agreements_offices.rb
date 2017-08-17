class DropAgreementsOffices < ActiveRecord::Migration
  def change
    drop_table :agreements_offices
  end
end
