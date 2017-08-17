class CreateActivityLogs < ActiveRecord::Migration
  def up
  
   create_table(:activity_logs) do |t|
      
    t.integer :comp_id 
    t.string :status
    t.integer :created_by 
    t.integer :updated_by
	  t.datetime :created_at
	  t.datetime :updated_at
	
	end
	
  end

  def down
  end
end
