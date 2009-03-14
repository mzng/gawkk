class AddLastAccessedAtToFeeds < ActiveRecord::Migration
  def self.up
    add_column :feeds, :last_accessed_at, :timestamp
    
    Feed.reset_column_information
    Feed.find(:all).each do |feed|
      if report = FeedImporterReport.find(:first, :conditions => ['feed_id = ?', feed.id], :order => 'created_at DESC')
        feed.update_attribute('last_accessed_at', report.created_at)
      else
        feed.update_attribute('last_accessed_at', Time.now)
      end
    end
  end

  def self.down
    remove_column :feeds, :last_accessed_at
  end
end
