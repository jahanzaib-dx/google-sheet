class DropCustomReportHeaderFields < ActiveRecord::Migration
  def change
    drop_table :custom_report_header_fields
  end
end
