class AddTruveoUrlToVideos < ActiveRecord::Migration
  def self.up
    add_column :videos, :truveo_url, :text, :default => ''
  end

  def self.down
    remove_column :videos, :truveo_url
  end
end
