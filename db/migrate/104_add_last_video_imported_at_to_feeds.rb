class AddLastVideoImportedAtToFeeds < ActiveRecord::Migration
  def self.up
    add_column :feeds, :last_video_imported_at, :timestamp
    
    Feed.reset_column_information
    Feed.find(:all).each do |feed|
      say "#{feed.id}, #{feed.url}"
      if report = FeedImporterReport.find(:first, :conditions => ['feed_id = ? AND videos_count > 0', feed.id])
        say " => report #{report.id}"
        feed.dont_recategorize = false
        feed.last_video_imported_at = report.created_at
        feed.save
        feed.dont_recategorize = true
      end
    end
  end

  def self.down
    remove_column :feeds, :last_video_imported_at
  end
end
