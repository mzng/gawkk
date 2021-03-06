class Subscription < ActiveRecord::Base
  belongs_to :user
  belongs_to :channel, :counter_cache => true
  
  has_one :news_item, :as => :actionable, :dependent => :destroy
  
  named_scope :recent, :order => 'created_at DESC'
  named_scope :for_channel, lambda {|channel| {:conditions => {:channel_id => channel.id}}}
  
  validates_uniqueness_of :channel_id, :scope => :user_id
  
  attr_accessor :silent
  
  
  def after_initialize
    self.silent = false
  end
  
  def after_create
    if self.silent == false and !User.default_followings.collect{|u| u.id}.include?(self.user_id)
      NewsItem.report(:type => 'subscribe_to_channel', :reportable => self.channel, :user_id => self.user_id, :actionable => self)
    end
    
    ##############################################################
    # Messaging Layer for SubscriptionMessages has been disabled #
    ##############################################################
    # if saved_video = self.channel.videos(:limit => 1).first
    #   saved_video.generate_message_for_subscriber!(self.user)
    # end
    
    Rails.cache.delete("subscription/user/#{self.user_id}/channel/#{self.channel_id}/status")
    Rails.cache.delete("users/#{self.user_id}/subscriptions/html")
    Rails.cache.delete("channels/#{self.channel_id}/subscribers")
    
    return true
  end
  
  def after_destroy
    Rails.cache.delete("subscription/user/#{self.user_id}/channel/#{self.channel_id}/status")
    Rails.cache.delete("users/#{self.user_id}/subscriptions/html")
    Rails.cache.delete("channels/#{self.channel_id}/subscribers")
    
    return true
  end
end
