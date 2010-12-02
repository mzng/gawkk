class Dislike < ActiveRecord::Base
  belongs_to  :user
  belongs_to  :video, :counter_cache => true

  named_scope :by_user, lambda {|user| {:conditions => {:user_id => user.id}}}
  named_scope :by_users, lambda {|user_ids| {:conditions => ['user_id IN (?)', user_ids]}}
  named_scope :not_user, lambda {|user_id| {:conditions => ['user_id != ?', user_id]}}
  named_scope :for_video, lambda {|video| {:conditions => {:video_id => video.id}}}
  named_scope :in_order, :order => 'created_at ASC'
  
  validates_uniqueness_of :video_id, :scope => :user_id


  def after_create
    Rails.cache.delete("videos/#{self.video_id}/dislikes")
    self.user.cache_dislike!(self)
    return true
  end

  def before_destroy
    Rails.cache.delete("videos/#{self.video_id}")
    Rails.cache.delete("videos/#{self.video_id}/likes")
    return true
  end

  def after_destroy
    self.user.uncache_dislike!(self)


    return true
  end
end
