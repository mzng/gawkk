class Subscription < ActiveRecord::Base
  belongs_to :user
  belongs_to :channel, :counter_cache => true
  
  named_scope :recent, :order => 'created_at DESC'
  named_scope :for_channel, lambda {|channel| {:conditions => {:channel_id => channel.id}}}
  
  attr_accessor :silent
  
  
  def after_initialize
    self.silent = false
  end
  
  def after_create
    NewsItem.report(:type => 'subscribe_to_channel', :reportable => self.channel, :user_id => self.user_id) if self.silent == false
    return true
  end
end
