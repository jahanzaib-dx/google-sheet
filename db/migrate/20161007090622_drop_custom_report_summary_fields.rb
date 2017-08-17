class DropCustomReportSummaryFields < ActiveRecord::Migration
  def change
    drop_table :custom_report_summary_fields
  end
end
