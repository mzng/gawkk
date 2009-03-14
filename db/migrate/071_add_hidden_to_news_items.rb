class AddHiddenToNewsItems < ActiveRecord::Migration
  def self.up
    add_column :news_items, :hidden, :boolean, :default => false, :null => false
  end

  def self.down
    remove_column :news_items, :hidden
  end
end
