class AddIndexToLikes < ActiveRecord::Migration
  def self.up
    add_index :likes, [:video_id, :user_id, :created_at]
  end

  def self.down
    remove_index :likes, [:video_id, :user_id, :created_at]
  end
end
