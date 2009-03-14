class AddNextVideosToVideos < ActiveRecord::Migration
  def self.up
    add_column :videos, :next_videos, :text, :default => ''
  end

  def self.down
    remove_column :videos, :next_videos
  end
end
