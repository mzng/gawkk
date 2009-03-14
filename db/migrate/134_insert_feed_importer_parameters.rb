class InsertFeedImporterParameters < ActiveRecord::Migration
  def self.up
    Parameter.create :name => 'number_of_regular_feed_importers', :value => '2'
    Parameter.create :name => 'number_of_fresh_feed_importers', :value => '1'
  end

  def self.down
    Parameter.find_by_name('number_of_fresh_feed_importers').destroy
    Parameter.find_by_name('number_of_regular_feed_importers').destroy
  end
end