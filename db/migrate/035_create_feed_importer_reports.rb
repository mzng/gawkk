class CreateFeedImporterReports < ActiveRecord::Migration
  def self.up
    create_table :feed_importer_reports do |t|
      t.column :feed_id, :integer
      t.column :videos_count, :integer, :default => 0, :null => false
      t.column :completed_successfully, :boolean, :default => false
      t.column :created_at, :timestamp
    end
    
    add_column :videos, :feed_importer_report_id, :integer
  end

  def self.down
    remove_column :videos, :feed_importer_report_id
    drop_table :feed_importer_reports
  end
end
