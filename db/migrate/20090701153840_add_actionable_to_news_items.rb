class AddActionableToNewsItems < ActiveRecord::Migration
  def self.up
    add_column :news_items, :actionable_type, :string
    add_column :news_items, :actionable_id, :integer, :references => nil
    
    NewsItem.reset_column_information
    NewsItem.find(:all, :conditions => 'comment_id IS NOT NULL').each do |news_item|
      news_item.actionable_type = 'Comment'
      news_item.actionable_id = news_item.comment_id
      news_item.save
    end
  end

  def self.down
    remove_column :news_items, :actionable_id
    remove_column :news_items, :actionable_type
  end
end
