class AddIndexes < ActiveRecord::Migration
  def self.up
    add_index 'videos', 'slug'
    add_index 'categories', 'slug'
    add_index 'users', 'username'
    add_index 'channels', 'slug'
  end

  def self.down
    remove_index 'channels', 'slug'
    remove_index 'users', 'username'
    remove_index 'categories', 'slug'
    remove_index 'videos', 'slug'
  end
end
