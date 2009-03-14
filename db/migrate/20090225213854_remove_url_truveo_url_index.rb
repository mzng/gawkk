class RemoveUrlTruveoUrlIndex < ActiveRecord::Migration
  def self.up
    remove_index :videos, :name => :urls
  end

  def self.down
    add_index :videos, [:url, :truveo_url], :name => "urls"
  end
end
