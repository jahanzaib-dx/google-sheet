class CreateScheduleAccesses < ActiveRecord::Migration
  def change
    create_table :schedule_accesses do |t|
      t.datetime :start_date_time
      t.datetime :end_date_time
      t.boolean :status
      t.references :user, index: true

      t.timestamps null: false
    end
    add_foreign_key :schedule_accesses, :users
  end
end
