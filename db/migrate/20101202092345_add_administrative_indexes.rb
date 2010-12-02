class AddAdministrativeIndexes < ActiveRecord::Migration
  def self.up
    add_index :videos, :dislikes_count
    add_index :videos, :likes_count
  end

  def self.down
    remove_index :videos, :dislikes_count
    remove_index :videos, :likes_count
  end
end
