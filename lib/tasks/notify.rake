namespace :notify do
	task :suggested => :environment do
	  User.find(:all, :conditions => ["feed_owner = false AND convert_tz(created_at, '+00:00', '-04:00') > ? AND convert_tz(created_at, '+00:00', '-04:00') < ?", Time.now - 2.hours, Time.now - 1.hour]).each do |user|
      user.friendships.each do |friendship|
        if !friendship.notification_sent? and friendship.friend.receives_each_follow_notification?
          FollowMailer.deliver_notification(friendship)
          friendship.update_attribute('notification_sent', true)
        end
      end
    end
  end
  
  task :follow_summaries => :environment do
    User.find(:all, :conditions => ["feed_owner = false AND follow_notification_type = ?", FollowNotificationType.SUMMARY]).each do |user|
      friendships = Friendship.find(:all, :conditions => ["notification_sent = false AND friend_id = ? AND convert_tz(created_at, '+00:00', '-04:00') < ?", user.id, Time.now - 1.hour])
      
      if friendships.size > 1
        FollowMailer.deliver_summary(friendships)
      elsif friendships.size == 1
        FollowMailer.deliver_notification(friendships.first)
      end
      
      friendships.each do |friendship|
        friendship.update_attribute('notification_sent', true)
      end
    end
  end
  
  task :channels_with_disabled_feeds => :environment do
    if (users = User.find(:all, :joins => :feeds, :conditions => 'feeds.active = false', :order => 'username')).size > 0
      DisabledFeedMailer.deliver_notification(users)
    end
  end
end