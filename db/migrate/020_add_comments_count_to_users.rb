class AddCommentsCountToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :comments_count, :integer, :default => 0, :null => false
    add_column :users, :my_comments_count, :integer, :default => 0, :null => false
  end

  def self.down
    remove_column :users, :comments_count
  end
end
