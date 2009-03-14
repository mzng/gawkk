class AddMutualToFriendships < ActiveRecord::Migration
  def self.up
    add_column :friendships, :mutual, :boolean, :default => false, :null => false
    
    Friendship.reset_column_information
    Friendship.find(:all).each { |friendship|
      if Friendship.count(:all, :conditions => ['user_id = ? AND friend_id = ?', friendship.friend_id, friendship.user_id]) > 0
        friendship.update_attribute('mutual', true)
      end
    }
  end

  def self.down
    remove_column :friendships, :mutual
  end
end
