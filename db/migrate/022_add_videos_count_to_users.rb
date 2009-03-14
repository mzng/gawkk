class AddVideosCountToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :videos_count, :integer, :default => 0, :null => false
  end

  def self.down
    remove_column :users, :videos_count
  end
end
