class CreateImportRequests < ActiveRecord::Migration
  def self.up
    create_table :import_requests do |t|
      t.integer :import_request_status_id, :channel_id, :videos_count
      t.timestamps
    end
  end

  def self.down
    drop_table :import_requests
  end
end
