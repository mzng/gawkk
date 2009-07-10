class SavedVideo < ActiveRecord::Base
  belongs_to  :channel, :counter_cache => :saves_count
  belongs_to  :video, :counter_cache => :saves_count
  
  named_scope :in_channel, lambda {|channel| {:include => :video, :conditions => {:channel_id => channel.id}, :order => 'id DESC'}}
  named_scope :in_channels, lambda {|channel_ids| {:select => '*, max(id) as max_id', :conditions => ['channel_id IN (?)', channel_ids], :group => 'video_id', :order => 'max_id DESC'}}
  named_scope :with_max_id_of, lambda {|max_id| {:conditions => ['id <= ?', max_id]}}
  
  
  def generate_message_for_subscriber!(subscriber)
    if !self.channel_id.blank? and !self.video_id.blank?
      SubscriptionMessage.create :user_id => subscriber.id, :saved_video_id => self.id, :video_id => self.video_id
    end
  end
  
  def generate_messages_for_subscribers!
    if !self.channel_id.blank? and !self.video_id.blank?
      subscriber_ids = Rails.cache.fetch("channels/#{self.channel_id}/subscribers", :expires_in => 1.week) do
        Subscription.for_channel(channel).all.collect{|subscriber| subscriber.user_id}
      end
      
      subscriber_ids << User.default_user.id if self.channel.suggested?
      
      subscriber_ids.each do |subscriber_id|
        SubscriptionMessage.create :user_id => subscriber_id, :saved_video_id => self.id, :video_id => self.video_id
      end
    end
  rescue Exception => e
    raise e
  end
end
