class DropCustomReportSummaryColumnNames < ActiveRecord::Migration
  def change
    drop_table :custom_report_summary_column_names
  end
end
