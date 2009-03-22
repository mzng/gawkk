class Friendship < ActiveRecord::Base
  belongs_to :user
  belongs_to :friend, :class_name => "User", :foreign_key => "friend_id"
  
  validates_presence_of :user_id, :friend_id
  
  
  def before_create
    self.auth_code = Util::AuthCode.generate(25) + Time.now.to_i.to_s
  end
  
  def after_create
    # Set mutual flags when appropriate
    if friendship = Friendship.find(:first, :conditions => ['user_id = ? AND friend_id = ?', self.friend_id, self.user_id])
      self.update_attribute('mutual', true)
      friendship.update_attribute('mutual', true)
    end
    
    spawn do
      FollowMailer.deliver_notification(self)
    end
    
    NewsItem.report(:type => 'add_a_friend', :reportable => self.friend, :user_id => self.user_id)
    return true
  end
  
  def before_destroy
    if friendship = Friendship.find(:first, :conditions => ['user_id = ? AND friend_id = ?', self.friend_id, self.user_id])
      friendship.update_attribute('mutual', false)
    end
    return true
  end
end
