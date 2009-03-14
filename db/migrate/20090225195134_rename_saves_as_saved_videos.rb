class RenameSavesAsSavedVideos < ActiveRecord::Migration
  def self.up
    rename_table :saves, :saved_videos
  end

  def self.down
    rename_table :saved_videos, :saves
  end
end
