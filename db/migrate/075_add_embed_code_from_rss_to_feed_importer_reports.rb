class AddEmbedCodeFromRssToFeedImporterReports < ActiveRecord::Migration
  def self.up
    add_column :feed_importer_reports, :embed_code_from_rss, :boolean, :default => false, :null => false
  end

  def self.down
    remove_column :feed_importer_reports, :embed_code_from_rss
  end
end
