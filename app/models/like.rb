class Like < ActiveRecord::Base
  belongs_to  :user
  belongs_to  :video, :counter_cache => true
  
  has_one :news_item, :as => :actionable
  
  named_scope :by_user, lambda {|user| {:conditions => {:user_id => user.id}}}
  named_scope :by_users, lambda {|user_ids| {:conditions => ['user_id IN (?)', user_ids]}}
  named_scope :not_user, lambda {|user_id| {:conditions => ['user_id != ?', user_id]}}
  named_scope :for_video, lambda {|video| {:conditions => {:video_id => video.id}}}
  named_scope :in_order, :order => 'created_at ASC'
  
  validates_uniqueness_of :video_id, :scope => :user_id
  
  
  def after_create
    NewsItem.report(:type => 'like_a_video', :reportable => self.video, :user_id => self.user_id, :actionable => self)
    
    spawn do
      # Tweet it
      if twitter_account = self.user.twitter_account and twitter_account.tweet_likes?
        Tweet.report('liked_a_video', self.user, self.video)
      end
      
      # Popularize and Tweet it if the liker is an administrator
      begin
        if Rails.env.production? and self.user.administrator? and !self.video.popular?
          tweet_type = TweetType.find_by_name('popularized_video')

          if Tweet.by_system.of_type(tweet_type).for_video(self.video).count == 0
            Tweet.create(:tweet_type_id => tweet_type.id, :reportable_type => 'Video', :reportable_id => self.video.id)

            tweet = Tweet.new
            tweet.tweet_type_id   = TweetType.find_by_name('liked_a_video').id
            tweet.reportable_type = 'Video'
            tweet.reportable_id   = self.video.id
            tweet.auth_code       = self.video.short_code
            
            access_token = '7820152-NpYUAyBrM5Zf0JFo9U0enpZgRz8RtrCrILomnmqEQ'
            access_secret = 'b1k8hpHiVktwJbo40zhzigH9dUlTNFduiFEUXSko'
            
            Util::Twitter.request(:post, '/statuses/update.json?status=' + CGI.escape(tweet.render), access_token, access_secret)
          end
          
          self.video.update_attribute('promoted_at', Time.now)
        end
      rescue
      end
    end
    
    Rails.cache.delete("like/user/#{self.user_id}/video/#{self.video_id}/status")
    Rails.cache.delete("videos/#{self.video_id}/likes")
    
    return true
  end
  
  def before_destroy
    if self.news_item
      if ActivityMessage.count(:all, :conditions => {:user_id => self.user_id, :news_item_id => self.news_item.id}) > 0
        # 1. Reverse ActivityMessage for self.user
        self.news_item.prepare_to_destroy_activity_messages!(self.user)

        # 2. Queue up a Job to generate ActivityMessages for all followers of self.user
        Job.enqueue(:type => JobType.find_by_name('activity_reversal'), :processable => self.news_item)
        
        # 3. Delete the activity message for self.user and self.news_item
        ActivityMessage.delete_all(:user_id => self.user_id, :news_item_id => self.news_item.id)
      end
    end
    
    Rails.cache.delete("videos/#{self.video_id}")
    Rails.cache.delete("videos/#{self.video_id}/likes")
    
    return true
  end
  
  def after_destroy
    Rails.cache.delete("like/user/#{self.user_id}/video/#{self.video_id}/status")
    
    return true
  end
end
