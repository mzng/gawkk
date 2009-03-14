class CreateFeeds < ActiveRecord::Migration
  def self.up
    add_column :users, :feed_owner, :boolean, :default => false, :null => false
    
    create_table :feeds do |t|
      t.column :category_id, :integer
      t.column :owned_by_id, :integer, :references => :users
      t.column :url, :string
    end
  end

  def self.down
    drop_table :feeds
    remove_column :users, :feed_owner
  end
end
