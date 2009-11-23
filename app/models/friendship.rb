class Friendship < ActiveRecord::Base
  belongs_to :user
  belongs_to :friend, :class_name => "User", :foreign_key => "friend_id"
  
  has_one :news_item, :as => :actionable, :dependent => :destroy
  
  named_scope :by_user, lambda {|user| {:conditions => ['user_id = ?', user.id]}}
  
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
        NewsItem.report(:type => 'add_a_friend', :reportable => self.friend, :user_id => self.user_id, :actionable => self)
      end
      
      if news_item = self.friend.last_action
        news_item.generate_message_for_user!(self.user)
      end
    end
    
    Rails.cache.delete("users/#{self.user_id}/followings/sidebar/html")
    Rails.cache.delete("users/#{self.user_id}/followers/sidebar/html")
    Rails.cache.delete("users/#{self.user_id}/friends/sidebar/html")
    
    return true
  end
  
  def before_destroy
    if friendship = Friendship.find(:first, :conditions => ['user_id = ? AND friend_id = ?', self.friend_id, self.user_id])
      friendship.update_attribute('mutual', false)
    end
    
    Rails.cache.delete("users/#{self.user_id}/followings/sidebar/html")
    Rails.cache.delete("users/#{self.user_id}/followers/sidebar/html")
    Rails.cache.delete("users/#{self.user_id}/friends/sidebar/html")
    
    return true
  end
end
