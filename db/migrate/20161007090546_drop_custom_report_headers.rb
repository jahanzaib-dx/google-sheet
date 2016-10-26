class DropCustomReportHeaders < ActiveRecord::Migration
  def change
    drop_table :custom_report_headers
  end
end
