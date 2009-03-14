class CreateImportRequestStatuses < ActiveRecord::Migration
  def self.up
    create_table :import_request_statuses do |t|
      t.string :name
    end
    
    ImportRequestStatus.reset_column_information
    ImportRequestStatus.create :name => 'open'
    ImportRequestStatus.create :name => 'processing'
    ImportRequestStatus.create :name => 'closed'
  end

  def self.down
    drop_table :import_request_statuses
  end
end
