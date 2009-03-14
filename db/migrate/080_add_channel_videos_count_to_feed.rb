class AddChannelVideosCountToFeed < ActiveRecord::Migration
  def self.up
    add_column :feeds, :channel_videos_count, :integer
    Feed.reset_column_information
    
    Feed.find(:all).each do |feed|
      feed.update_attribute('channel_videos_count', Video.count(:all, :joins => 'LEFT JOIN feed_importer_reports ON videos.feed_importer_report_id = feed_importer_reports.id', :conditions => ['feed_importer_reports.feed_id = ?', feed.id]))
    end
  end

  def self.down
    remove_column :feeds, :channel_videos_count
  end
end
