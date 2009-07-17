class Comment < ActiveRecord::Base
  belongs_to :commentable, :polymorphic => true, :counter_cache => true
  belongs_to :user, :counter_cache => 'my_comments_count'
  
  has_one :news_item, :as => :actionable, :dependent => :destroy
  
  named_scope :in_order, :order => 'created_at ASC'
  named_scope :in_reverse_order, :order => 'created_at DESC'
  named_scope :threads, :select => 'DISTINCT thread_id'
  named_scope :in_thread, lambda {|thread_id| {:conditions => ['thread_id LIKE BINARY ?', thread_id]}}
  named_scope :in_threads, lambda {|thread_ids| {:conditions => ['thread_id COLLATE latin1_bin IN (?)', thread_ids]}}
  named_scope :not_user, lambda {|user_id| {:conditions => ['user_id != ?', user_id]}}
  named_scope :by_users, lambda {|user_ids| {:conditions => ['user_id IN (?)', user_ids]}}
  named_scope :for_commentable, lambda {|commentable| {:conditions => {:commentable_type => commentable.class.name, :commentable_id => commentable.id}}}
  named_scope :for_commentable_type, lambda {|commentable_type| {:conditions => {:commentable_type => commentable_type}}}
  
  
  def after_create
    # Generate a new thread_id if this comment isn't already part of a thread
    if self.thread_id.blank?
      self.update_attribute('thread_id', Util::BaseConverter.to_base54(self.id))
    end
    
    news_item = NewsItem.report(:type => 'make_a_comment', :reportable => self.commentable, :user_id => self.user_id, :thread_id => self.thread_id, :message => self.body, :actionable => self)
    
    spawn do
      if self.commentable_type == 'Video'
        likers      = Util::Cache.collect_users_from_likes(Like.for_video(self.commentable).not_user(self.user_id).all)
        commenters  = Util::Cache.collect_users_from_comments(Comment.in_thread(self.thread_id).not_user(self.user_id).all)
        
        if !self.commentable.posted_by.feed_owner and self.commentable.posted_by.id != self.user_id
          likers << self.commentable.posted_by
        end
        
        likers.concat(commenters).uniq.each do |user|
          details = Hash.new
          details[:sender]    = self.user
          details[:recipient] = user
          details[:video]     = self.commentable
          details[:nid]       = news_item.id if news_item
          details[:thread_id] = self.thread_id
          
          DiscussionMailer.deliver_notification(details)
        end
      end
    end
    
    return true
  end
  
  
  def self.thread_ids_for(user_ids, commentable)
    Comment.threads.by_users(user_ids).for_commentable(commentable).all.collect{|c| c.thread_id}
  end
end
