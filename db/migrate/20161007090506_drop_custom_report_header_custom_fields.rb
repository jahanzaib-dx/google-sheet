class DropCustomReportHeaderCustomFields < ActiveRecord::Migration
  def change
    drop_table :custom_report_header_custom_fields
  end
end
