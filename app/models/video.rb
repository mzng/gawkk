class Video < ActiveRecord::Base
  belongs_to  :category
  belongs_to  :posted_by, :class_name => "User", :foreign_key => "posted_by_id", :counter_cache => true
  
  has_many    :comments, :as => :commentable, :order => 'created_at DESC', :dependent => :destroy
  has_many    :saved_videos, :dependent => :destroy
  
  validates_presence_of   :category_id, :name, :url, :posted_by_id
  validates_uniqueness_of :url, :on => :create, :message => "must be unique"
  
  attr_accessor :master_score
  
  named_scope :newest, :select => 'id, posted_at', :order => 'posted_at DESC'
  named_scope :popular, :select => 'id, promoted_at', :conditions => 'promoted_at IS NOT NULL', :order => 'promoted_at DESC'
  named_scope :allowed_on_front_page, lambda {{:select => 'id, category_id', :conditions => ['category_id IN (?)', Category.allowed_on_front_page]}}
  named_scope :in_category, lambda {|category| {:select => 'id, category_id', :conditions => {:category_id => category.id}}}
  named_scope :in_categories, lambda {|categories| {:select => 'id, category_id', :conditions => ['category_id IN (?)', categories]}}
  
  
  define_index do
    indexes :name
    indexes :description
    has category_id
    has posted_at
  end
  
  
  def to_param
    self.slug
  end
  
  def long_cache_key
    !self.slug.blank? ? "videos/#{self.slug.first(225)}" : nil
  end
  
  
  def title
    self.name
  end
  
  def safe_description
    self.description.blank? ? self.title : self.description
  end
  
  def first_channel
    if self.saved_videos.first
      self.saved_videos.first.channel
    else
      nil
    end
  end
  
  def host
    host = self.url
    
    begin
      host = URI.parse(host).host                             # Remove leading http:// and trailing path and query string
      host = host[4, host.length] if host[0, 4] == 'www.'     # Remove leading www.
    rescue
      host = self.url
      host = host[7, host.length] if host[0, 7] == 'http://'  # Remove leading http://
      host = host[4, host.length] if host[0, 4] == 'www.'     # Remove leading www.
      host = host[0, host.index('/')] if host.index('/')      # Remove trailing path and query string
    end
    
    return host
  end
  
  def popular?
    return self.promoted_at.nil? ? false : true
  end
  
  
  def likes_by(user, include_friends = true)
    user_ids = Array.new
    
    user_ids << user.id
    if include_friends
      user_ids.concat(user.followings_ids)
    end
    
    likes = Like.by_users(user_ids).for_video(self).in_order.all
    
    if likes.size > 0
      yield likes
    end
  end
  
  def comments_by(user, include_friends = true)
    user_ids = Array.new
    
    user_ids << user.id
    if include_friends
      user_ids.concat(user.followings_ids)
    end
    
    thread_ids = Comment.thread_ids_for(user_ids, self)
    comments = Comment.in_threads(thread_ids).in_order.all
    
    yield comments
  end
end
