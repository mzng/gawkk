class Like < ActiveRecord::Base
  belongs_to  :user
  belongs_to  :video, :counter_cache => true
  
  named_scope :by_user, lambda {|user| {:conditions => {:user_id => user.id}}}
  named_scope :by_users, lambda {|user_ids| {:conditions => ['user_id IN (?)', user_ids]}}
  named_scope :not_user, lambda {|user_id| {:conditions => ['user_id != ?', user_id]}}
  named_scope :for_video, lambda {|video| {:conditions => {:video_id => video.id}}}
  named_scope :in_order, :order => 'created_at ASC'
  
  
  def after_create
    NewsItem.report(:type => 'like_a_video', :reportable => self.video, :user_id => self.user_id)
    
    spawn do
      if twitter_account = self.user.twitter_account and twitter_account.tweet_likes?
        Tweet.report('liked_a_video', self.user, self.video)
      end
    end
    
    return true
  end
  
  def before_destroy
    Rails.cache.delete("videos/#{video_id}")
    return true
  end
end
