class Friendship < ActiveRecord::Base
  belongs_to :user
  belongs_to :friend, :class_name => "User", :foreign_key => "friend_id"
  
  validates_presence_of   :user_id, :friend_id
  validates_uniqueness_of :friend_id, :scope => :user_id
  
  attr_accessor :silent
  
  
  def after_initialize
    self.silent = false
  end
  
  def before_create
    self.auth_code = Util::AuthCode.generate(25) + Time.now.to_i.to_s
  end
  
  def after_create
    # Set mutual flags when appropriate
    if friendship = Friendship.find(:first, :conditions => ['user_id = ? AND friend_id = ?', self.friend_id, self.user_id])
      self.update_attribute('mutual', true)
      friendship.update_attribute('mutual', true)
    end
    
    if self.silent == false
      spawn do
        if self.friend.receives_each_follow_notification?
          FollowMailer.deliver_notification(self)
          self.update_attribute('notification_sent', true)
        end
      end
      
      if !User.default_followings.collect{|u| u.id}.include?(self.user_id)
        NewsItem.report(:type => 'add_a_friend', :reportable => self.friend, :user_id => self.user_id)
      end
    end
    
    return true
  end
  
  def before_destroy
    if friendship = Friendship.find(:first, :conditions => ['user_id = ? AND friend_id = ?', self.friend_id, self.user_id])
      friendship.update_attribute('mutual', false)
    end
    
    return true
  end
end
