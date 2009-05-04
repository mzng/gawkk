class AddHashedUrlToVideos < ActiveRecord::Migration
  def self.up
    add_column :videos, :hashed_url, :string
  end
  
  def self.down
    remove_column :videos, :hashed_url
  end
end
