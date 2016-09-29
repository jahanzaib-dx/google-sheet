class RenameGroupMembersToMemberships < ActiveRecord::Migration
  def change
    rename_table :group_members, :memberships
  end
end
