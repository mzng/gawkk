class Like < ActiveRecord::Base
  belongs_to  :user
  belongs_to  :video, :counter_cache => true
  
  named_scope :by_user, lambda {|user| {:conditions => {:user_id => user.id}}}
  named_scope :by_users, lambda {|user_ids| {:conditions => ['user_id IN (?)', user_ids]}}
  named_scope :not_user, lambda {|user_id| {:conditions => ['user_id != ?', user_id]}}
  named_scope :for_video, lambda {|video| {:conditions => {:video_id => video.id}}}
  named_scope :in_order, :order => 'created_at ASC'
  
  validates_uniqueness_of :video_id, :scope => :user_id
  
  
  def after_create
    NewsItem.report(:type => 'like_a_video', :reportable => self.video, :user_id => self.user_id)
    
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

            twitter = Util::Twitter.client
            twitter.status(:post, tweet.render)
          end
          
          self.video.update_attribute('promoted_at', Time.now)
        end
      rescue
      end
    end
    
    return true
  end
  
  def before_destroy
    Rails.cache.delete("videos/#{video_id}")
    return true
  end
end
