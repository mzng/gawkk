class AddMatureToNewsItems < ActiveRecord::Migration
  def self.up
    add_column :news_items, :mature, :boolean, :default => false, :null => false
  end

  def self.down
    remove_column :news_items, :mature
  end
end
