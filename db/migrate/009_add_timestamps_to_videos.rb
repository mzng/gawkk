class AddTimestampsToVideos < ActiveRecord::Migration
  def self.up
    add_column :videos, :posted_at, :timestamp
    add_column :videos, :promoted_at, :timestamp
  end

  def self.down
    remove_column :videos, :promoted_at
    remove_column :videos, :posted_at
  end
end
