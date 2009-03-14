class AddVideosInFeedToFeedImporterReports < ActiveRecord::Migration
  def self.up
    add_column :feed_importer_reports, :items_in_feed, :integer, :default => 0, :null => false
  end

  def self.down
    remove_column :feed_importer_reports, :items_in_feed
  end
end
