require 'digest/sha1'

class Video < ActiveRecord::Base
  belongs_to  :category
  belongs_to  :posted_by, :class_name => "User", :foreign_key => "posted_by_id", :counter_cache => true
  
  has_many    :comments, :as => :commentable, :order => 'created_at DESC', :dependent => :destroy
  has_many    :likes, :dependent => :destroy
  has_many    :dislikes, :dependent => :destroy
  has_many    :news_items, :as => :reportable, :dependent => :destroy
  has_many    :saved_videos, :dependent => :destroy
  
  # Legacy votes table, defined here for destroys only
  has_many :votes, :dependent => :destroy
  
  validates_presence_of   :category_id, :name, :url, :posted_by_id
  validates_uniqueness_of :hashed_url, :on => :create, :message => "must be unique"
  
  attr_accessor :master_score
  
  named_scope :newest, :select => 'id, posted_at', :order => 'id DESC'
  named_scope :popular, :select => 'id', :conditions => "popularity_score IS NOT NULL", :order => "popularity_score desc"
  named_scope :allowed_on_front_page, lambda {{:select => 'id, category_id', :conditions => ['category_id IN (?)', Category.allowed_on_front_page_ids]}}
  named_scope :in_category, lambda {|category| {:select => 'id, category_id', :conditions => ['category_id = ?', category.id]}}
  named_scope :in_categories, lambda {|categories| {:select => 'id, category_id', :conditions => ['category_id IN (?)', categories]}}
  named_scope :with_max_id_of, lambda {|max_id| max_id.blank? ? {} : {:conditions => ['id <= ?', max_id]}}
  
  
  define_index do
    indexes :name
    indexes :description
    has category_id
    has posted_at
  end
  
  
  def before_create
    self.slug         = Util::Slug.generate(self.name)
    self.url          = Util::Scrub.url(self.url)
    self.hashed_url   = Digest::SHA2.hexdigest(self.url.nil? ? '' : self.url)
    self.description  = '' if self.description.nil?
    self.embed_code   = Util::EmbedCode.generate(self, self.url)
    self.posted_at    = Time.now
    
    return true
  end
  
  def after_create
    self.update_attribute('short_code', Util::BaseConverter.to_base54(self.id))
    
    return true
  end

  def after_save
    if self.likes_count && self.likes_count > self.dislikes_count
      ActiveRecord::Base.connection.execute "
      UPDATE videos 
      SET popularity_score = log10(likes_count - dislikes_count) + (datediff(posted_at, '2007-01-01 00:00:00.0000')/500) 
      WHERE id = #{self.id}"
    elsif self.popularity_score
      ActiveRecord::Base.connection.execute "
      UPDATE videos 
      SET popularity_score = null
      WHERE id = #{self.id}"
    end

  end
  
  def before_save
    self.description  = '' if self.description.nil?
    self.embed_code   = Util::EmbedCode.scrub(self.embed_code)
    self.hashed_url   = Digest::SHA2.hexdigest(self.url.nil? ? '' : self.url)
    
    self.news_items.each do |news_item|
      Rails.cache.delete(news_item.cache_key)
    end
    
    return true
  end
  
  def before_destroy
    
    return true
  end
  
  
  def to_param
    self.slug
  end
  
  def long_cache_key
    !self.slug.blank? ? "videos/#{self.slug.first(225)}" : nil
  end
  
  def cache!
    Rails.cache.write(self.cache_key, Video.find(self.id, :include => [:category, :posted_by, {:saved_videos => {:channel => :user}}]), :expires_in => 1.week)
  end
  
  
  def user_id=(user_id)
    self.posted_by_id = user_id
  end
  
  def title
    self.name.blank? ? '' : self.name
  end

  def title=(title)
    self.name = title
  end
  
  def safe_description
    self.description.blank? ? self.title : self.description
  end
  
  def summarized_description
    summary = Hpricot(Util::Scrub.html(self.safe_description)).to_plain_text
    summary = Util::Scrub.html(summary)
    
    if summary.length > 160
      return summary.first(160).concat('...')
    else
      return summary
    end
  end
  
  def safe_embed_code
    return self.embed_code.gsub(/'/,'"')
  end
  
  def first_channel
    Rails.cache.fetch("videos/#{self.id}/first-channel", :expires_in => 1.week) do
      if saved_video = self.saved_videos.first
        Channel.find(:first, :include => :user, :conditions => {:id => saved_video.channel_id})
      else
        nil
      end
    end
  end
  
  def cached_category
    Rails.cache.fetch("categories/#{self.category_id}", :expries_in => 1.week) do
      Category.find(self.category_id)
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
  
  
  def likes_by(user = nil, include_friends = true)
    if user.nil?
      likes = Rails.cache.fetch("videos/#{self.id}/likes", :expires_in => 1.day) do
        Like.for_video(self).in_order.all
      end
    else
      user_ids = Array.new
      
      user_ids << user.id
      if include_friends
        user_ids.concat(user.followings_ids)
      end
      
      likes = Like.by_users(user_ids).for_video(self).in_order.all
    end
    
    if likes.size > 0
      yield likes
    end
  end
  
  def comments_by(user, include_friends = true)
    if !user.nil?
      user_ids = Array.new

      user_ids << user.id
      if include_friends
        user_ids.concat(user.followings_ids)
      end

      thread_ids = Comment.thread_ids_for(user_ids, self)
      comments = Comment.in_threads(thread_ids).in_order.all
    else
      comments = Comment.for_commentable(self).in_order.all
    end
    
    yield Util::Cache.collect_comments(comments)
  end
  
  def tags(*args)
    options = args.extract_options!
  
    tags = Util::Scrub.query(self.title.downcase, true, false).split
  
    if options[:generate_phrases] and tags.size > 1
      phrases = Array.new
    
      (1..(tags.size - 1)).each do |i|
        phrases << tags[i - 1] + ' ' + tags[i]
      end
    
      tags.concat(phrases)
    end
  
    return tags
  end
  
  
  def retrieve_truveo_redirect
    begin
      self.truveo_url = self.url
      if self.truveo_url.downcase[/^(http|https):\/\/xml\.truveo\.com\//]
        html = Hpricot(open(self.truveo_url))
        if html.at('meta') and html.at('meta')['content']
          self.url = html.at('meta')['content'][6, html.at('meta')['content'].length - 2]
        end
      end
      self.save
    rescue
    end
  end
end
