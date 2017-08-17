class CreateCompRequests < ActiveRecord::Migration
  def change
    create_table :comp_requests do |t|
      t.references :comp, index: true
      t.references :initiator, index: true
      t.references :receiver, index: true

      t.timestamps
    end

  end
end
