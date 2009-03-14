class AddThumbnailCountToFeedImporterReports < ActiveRecord::Migration
  def self.up
    add_column :feed_importer_reports, :thumbnail_count, :integer, :default => 0, :null => false
  end

  def self.down
    remove_column :feed_importer_reports, :thumbnail_count
  end
end
