class AddCommentIdToNewsItems < ActiveRecord::Migration
  def self.up
    add_column :news_items, :comment_id, :integer
  end

  def self.down
    remove_column :news_items, :comment_id
  end
end
