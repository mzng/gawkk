class Vote < ActiveRecord::Base
  belongs_to  :user
  belongs_to  :video
  
  named_scope :positive, :conditions => 'value > 0'
  named_scope :negative, :conditions => 'value < 0'
  named_scope :by_user, lambda {|user| {:conditions => {:user_id => user.id}}}
  named_scope :by_users, lambda {|user_ids| {:conditions => ['user_id IN (?)', user_ids]}}
  named_scope :for_video, lambda {|video| {:conditions => {:video_id => video.id}}}
  named_scope :in_order, :order => 'created_at ASC'
  
  def before_save
    Rails.cache.delete("videos/#{video_id}")
  end
  
  def after_save
    if video = Video.find(video_id, :include => [:category, {:saved_videos => {:channel => :user}}])
      video.votes_count = Vote.sum(:value, :conditions => ['video_id = ?', self.video_id])
      video.member_votes_count = Vote.sum(:value, :conditions => ['video_id = ? AND feed_owner = false', self.video_id])
      video.save
      
      Rails.cache.write(video.cache_key, video, :expires_in => 1.day)
    end
  end
  
  
  def self.like(user, video)
    if vote = Vote.by_user(user).for_video(video).first and user.administrator?
      vote.update_attribute('value', vote.value + 1)
    elsif vote.nil?
      vote = Vote.create(:user_id => user.id, :video_id => video.id, :value => 1)
    end
    
    vote
  end
end
