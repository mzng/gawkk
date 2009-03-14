class CleanUpFriendshipSubscriptions < ActiveRecord::Migration
  def self.up
    subscription_ids = Subscription.find(:all, :select => 'subscriptions.*', :include => :channel, :conditions => 'channels.user_owned = true').collect{|subscription| subscription.id}
    Subscription.delete(subscription_ids)
  end

  def self.down
    
  end
end
