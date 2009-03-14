class AddShortCodeToVideos < ActiveRecord::Migration
  def self.up
    add_column :videos, :short_code, :string
  end

  def self.down
    remove_column :videos, :short_code
  end
end
