class Comment < ActiveRecord::Base
  belongs_to  :commentable, :polymorphic => true, :counter_cache => true
  belongs_to  :user, :counter_cache => 'my_comments_count'
  
  named_scope :in_order, :order => 'created_at ASC'
  named_scope :threads, :select => 'DISTINCT thread_id'
  named_scope :in_threads, lambda {|thread_ids| {:conditions => ['thread_id COLLATE latin1_bin IN (?)', thread_ids]}}
  named_scope :by_users, lambda {|user_ids| {:conditions => ['user_id IN (?)', user_ids]}}
  named_scope :for_commentable, lambda {|commentable| {:conditions => {:commentable_type => commentable.class.name, :commentable_id => commentable.id}}}
  
  def after_create
    # Generate a new thread_id if this comment isn't already part of a thread
    if self.thread_id.blank?
      self.update_attribute('thread_id', Util::BaseConverter.to_base54(self.id))
    end
  end
  
  
  def self.thread_ids_for(user_ids, commentable)
    Comment.threads.by_users(user_ids).for_commentable(commentable).all.collect{|c| c.thread_id}
  end
end
