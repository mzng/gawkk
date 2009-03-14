class AddPlaylistIdToFeeds < ActiveRecord::Migration
  def self.up
    add_column :feeds, :playlist_id, :integer
  end

  def self.down
    remove_column :feeds, :playlist_id
  end
end
