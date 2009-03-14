class AddMinutesUntilNextFetchToFeedImporterReports < ActiveRecord::Migration
  def self.up
    add_column :feed_importer_reports, :minutes_until_next_fetch, :integer, :default => 0, :null => false
  end

  def self.down
    remove_column :feed_importer_reports, :minutes_until_next_fetch
  end
end
