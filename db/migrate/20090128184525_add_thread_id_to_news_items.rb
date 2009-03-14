class AddThreadIdToNewsItems < ActiveRecord::Migration
  def self.up
    add_column :news_items, :thread_id, :string, :references => nil
  end

  def self.down
    remove_column :news_items, :thread_id
  end
end
