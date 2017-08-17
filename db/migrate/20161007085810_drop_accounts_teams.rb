class DropAccountsTeams < ActiveRecord::Migration
  def change
    drop_table :accounts_teams
  end
end
