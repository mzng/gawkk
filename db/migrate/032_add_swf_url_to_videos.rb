class AddSwfUrlToVideos < ActiveRecord::Migration
  def self.up
    add_column :videos, :swf_url, :string, :default => '', :null => false
  end

  def self.down
    remove_column :videos, :swf_url
  end
end
