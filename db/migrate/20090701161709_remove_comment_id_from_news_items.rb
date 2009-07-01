class RemoveCommentIdFromNewsItems < ActiveRecord::Migration
  def self.up
    remove_column :news_items, :comment_id
  end

  def self.down
    add_column :news_items, :comment_id, :integer, :references => nil
  end
end
