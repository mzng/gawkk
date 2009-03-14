class AddLatestAndEarliestVideoToChannels < ActiveRecord::Migration
  def self.up
    add_column :channels, :earliest_video_id, :integer, :references => :videos
    add_column :channels, :latest_video_id, :integer, :references => :videos
  end

  def self.down
    remove_column :channels, :latest_video_id
    remove_column :channels, :earliest_video_id
  end
end
