class RemoveIndexes < ActiveRecord::Migration
  def self.up
    remove_index 'videos', 'slug'
    remove_index 'categories', 'slug'
    remove_index 'users', 'username'
    remove_index 'channels', 'slug'
  end

  def self.down
    add_index 'channels', 'slug'
    add_index 'users', 'username'
    add_index 'categories', 'slug'
    add_index 'videos', 'slug'
  end
end
