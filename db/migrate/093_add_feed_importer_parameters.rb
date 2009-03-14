class AddFeedImporterParameters < ActiveRecord::Migration
  def self.up
    Parameter.find_by_name('allow_feed_imports').destroy
    Parameter.create :name => 'feed_importer_status', :value => 'false'
  end

  def self.down
    Parameter.find_by_name('feed_importer_status').destroy
    Parameter.create :name => 'allow_feed_imports', :value => 'true'
  end
end
