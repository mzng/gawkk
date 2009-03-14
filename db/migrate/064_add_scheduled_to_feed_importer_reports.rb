class AddScheduledToFeedImporterReports < ActiveRecord::Migration
  def self.up
    add_column :feed_importer_reports, :scheduled, :boolean, :default => false, :null => false
  end

  def self.down
    remove_column :feed_importer_reports, :scheduled
  end
end
