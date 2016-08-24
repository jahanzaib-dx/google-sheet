class CreateConnectionRequests < ActiveRecord::Migration
  def change
    create_table :connection_requests do |t|

      t.references :user, index: true
      t.references :agent, index: true

      t.string :message
      t.string :request_code    # added after the requirement by client that user should be able to invite users to system

      t.timestamps
    end
  end
end
