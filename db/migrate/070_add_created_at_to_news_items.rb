class AddCreatedAtToNewsItems < ActiveRecord::Migration
  def self.up
    add_column :news_items, :created_at, :timestamp
  end

  def self.down
    remove_column :news_items, :created_at
  end
end
