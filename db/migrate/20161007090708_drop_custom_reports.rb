class DropCustomReports < ActiveRecord::Migration
  def change
    drop_table :custom_reports
  end
end
