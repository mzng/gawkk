require 'digest/sha1'

class User < ActiveRecord::Base
  belongs_to :age_range
  
  has_one :twitter_account, :dependent => :destroy
  has_one :facebook_account, :dependent => :destroy
  
  has_many :activity_messages, :class_name => "ActivityMessage"
  has_many :channels, :class_name => "Channel", :order => 'channels.created_at', :dependent => :destroy
  has_many :comments, :class_name => "Comment", :foreign_key => "user_id", :dependent => :destroy
  has_many :feeds, :class_name => "Feed", :foreign_key => "owned_by_id", :dependent => :destroy
  has_many :likes, :class_name => "Like", :foreign_key => "user_id", :dependent => :destroy
  has_many :news_items, :class_name => "NewsItem", :foreign_key => "user_id", :dependent => :destroy
  has_many :news_items_about_me, :class_name => "NewsItem", :as => :reportable, :dependent => :destroy
  has_many :subscriptions, :class_name => "Subscription", :dependent => :destroy
  has_many :videos, :class_name => "Video", :foreign_key => "posted_by_id", :dependent => :destroy
  
  # Legacy votes table, defined here for destroys only
  has_many :votes, :dependent => :destroy
  
  
  # A Friendship is actually a one way follow.
  # Gawkk relationships are defiend as:
  # 
  # followers   - Who is following this user
  # followings  - Who this user is following
  # friends     - The intersection of followers and followings
  # 
  # These relationships are complex and architectually based on a one way follow.
  # Rather than defining simple has_many relationships here, utility methods are available.
  
  has_many :friendships, :class_name => "Friendship", :foreign_key => "user_id", :dependent => :destroy
  has_many :friendships_with_me, :class_name => "Friendship", :foreign_key => "friend_id", :dependent => :destroy
  
  
  named_scope :members, :select => 'id, username, last_login_at', :conditions => {:feed_owner => false}
  named_scope :active, :conditions => ['login_count > 2']
  named_scope :with_ids, lambda {|user_ids| {:conditions => ['id IN (?)', user_ids]}}
  named_scope :with_slug, lambda {|slug| {:conditions => ['lower(slug) = lower(?)', slug]}}
  named_scope :with_slugs, lambda {|slugs| {:conditions => ['slug IN (?)', slugs]}}
  named_scope :followings_of, lambda {|user| {:joins => 'LEFT OUTER JOIN `friendships` ON friendships.friend_id = users.id', :conditions => ['friendships.user_id = ?', user.id]}}
  named_scope :followers_of, lambda {|user| {:joins => :friendships, :conditions => ['friendships.friend_id = ?', user.id]}}
  named_scope :friends_of, lambda {|user| {:joins => 'LEFT OUTER JOIN `friendships` ON friendships.friend_id = users.id', :conditions => ['friendships.user_id = ? AND friendships.mutual = true', user.id]}}
  named_scope :except, lambda {|user_ids| {:conditions => ['id NOT IN (?)', user_ids]}}
  named_scope :member_since_at_least, lambda {|timestamp| {:conditions => ['feed_owner = false AND created_at > ?', timestamp]}}
  
  
  attr_accessor   :password, :password_confirmation, :external_services
  
  attr_accessible :administrator, :username, :slug, :password, :password_confirmation, :name, :email, :last_login_at, :created_at
  attr_accessible :salt, :cookie_hash, :password_reset_auth_code, :password_reset_expires_at, :email_confirmation_auth_code, :email_confirmed_at
  attr_accessible :description, :age_range_id, :age_range, :location, :sex, :zip_code
  attr_accessible :twitter_username, :youtube_username, :friendfeed_username, :website_url, :feed_url, :external_services
  attr_accessible :consumes_grouped_activity, :safe_search, :category_notice_dismissed, :invite_friends_notice_dismissed
  attr_accessible :send_digest_emails, :digest_email_frequency, :follow_notification_type
  attr_accessible :friends_version, :friends_channels_cache, :subscribed_channels_cache, :using_default_friends, :using_default_subscriptions
  attr_accessible :feed_owner, :twitter_oauth, :facebook
  attr_accessible :ip_address
  
  validates_presence_of     :username
  validates_presence_of     :password, :on => :create, :message => "can't be blank"
  validates_confirmation_of :password, :on => :save, :message => "should match confirmation"
  validates_length_of       :description, :maximum => 160, :allow_blank => true, :message => "must be less than 160 characters"
  validates_format_of       :website_url, :with => URI.regexp, :allow_blank => true, :on => :save
  
  
  define_index do
    indexes :username
    indexes :name
    indexes :email
    has feed_owner
  end
  
  
  def validate_on_create
    errors.add(:username,   "must be at least 4 characters") unless self.username.length > 3 or self.feed_owner?
    errors.add(:username,   "can't be longer than 15 characters") unless self.username.length < 16 or self.feed_owner?
    errors.add(:username,   "can't contain any spaces") unless !self.username.match(/\s/) or self.feed_owner?
    errors.add(:username,   "can't contain any periods") unless !self.username.match(/\./)
    errors.add(:username,   "must be unique") unless User.unique_username?(self.username)
    errors.add(:email,      "must be unique") unless User.unique_email?(self.email)
    errors.add(:email,      "can't be blank") unless !self.email.blank?
    errors.add(:email,      "entered is not a valid email address") unless self.email.match(/^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/)
    errors.add(:password,   "must be at least six characters long") unless self.password.length > 5 or self.feed_owner?
  end
  
  def before_create
    self.hashed_password              = User.hash_password(self.password)
    self.email_confirmation_auth_code = Util::AuthCode.generate(25)
    self.salt                         = [Array.new(6){rand(256).chr}.join].pack("m").chomp
    self.slug                         = Util::Slug.generate(self.username, false)
    self.thumbnail                    = Util::Avatar.random
    self.youtube_username             = ''
    self.digest_email_frequency       = (self.send_digest_emails ? 3 : 0)
  end
  
  def after_create
    # Create Channel
    channel = Channel.new
    channel.name = self.username + ' Channel'
    channel.description = 'Personal Channel of ' + self.username
    channel.user_id = self.id
    channel.user_owned = !self.feed_owner?
    channel.save
    
    if !self.feed_owner?
      # Setup default followings
      User.default_followings.each do |user|
        friendship = Friendship.new
        friendship.user_id    = self.id
        friendship.friend_id  = user.id
        friendship.silent     = true
        friendship.save
        
        if news_item = user.last_action
          news_item.generate_message_for_user!(self)
        end
        
        Rails.cache.delete("users/#{user.id}/followers")
      end
      
      # Setup default subscriptions
      Channel.default_subscriptions.each do |channel|
        subscription = Subscription.new
        subscription.user_id    = self.id
        subscription.channel_id = channel.id
        subscription.silent     = true
        subscription.save
      end
      
      # Ensure the follow and subscription caches are clean
      Rails.cache.delete("users/#{self.id}/followings")
      Rails.cache.delete("users/#{self.id}/followings/count")
      Rails.cache.delete("users/#{self.id}/followings/random")
      
      Rails.cache.delete("users/#{self.id}/followers/count")
      Rails.cache.delete("users/#{self.id}/followers/random")
      
      Rails.cache.delete("users/#{self.id}/friends/count")
      Rails.cache.delete("users/#{self.id}/friends/random")
      
      Rails.cache.delete("users/#{self.id}/subscriptions")
      
      # Setup YouTube feed for importer
      if !self.youtube_username.blank?
        # Feed.create :category_id => Category.find_by_slug('uncategorized').id, :owned_by_id => self.id, :url => "http://www.youtube.com/rss/user/#{self.youtube_username}/videos.rss", :active => true
      end
      
      # Send welcome email
      unless self.facebook? and self.email[/^fb\-app\-user/] and self.email[/@gawkk\.com$/]
        spawn(:nice => 10) do
          RegistrationMailer.deliver_notification(self)
        end
      end
    end
  end

  def before_save
    if self.password != nil && self.password != ''
      self.hashed_password = User.hash_password(self.password)
    end
    
    # remove caches for this user
    Rails.cache.delete(self.cache_key)
    
    self.channels.each do |channel|
      Rails.cache.delete(channel.cache_key)
    end
  end
  
  def before_destroy
    ActivityMessage.delete_all(:user_id => self.id)
    
    ##############################################################
    # Messaging Layer for SubscriptionMessages has been disabled #
    ##############################################################
    # SubscriptionMessage.delete_all(:user_id => self.id)
    
    return true
  end
  
  
  def to_param
    self.slug
  end

  def long_cache_key
    "users/#{self.slug}"
  end
  
  def active?
    self.id.blank? or (self.login_count > 2)
  end
  
  def preferred_username
    self.facebook_username.blank? ? self.username : self.facebook_username
  end
  
  def summary_description
    description = self.description.blank? ? '' : self.description
    
    if description.length > 65
      description = description.first(65) + '...'
    end
    
    if description.blank?
      description = '&nbsp;'
    end
    
    return description
  end
  
  def default_avatar?
    (!self.thumbnail.blank? and self.thumbnail[/^avatars\//]) ? true : false
  end
  
  def auto_tweet?
    (!self.id.nil? and self.twitter_account and self.twitter_account.authenticated?) ? true : false
  end
  
  def services
    if self.external_services.nil?
      self.external_services = Array.new
      self.external_services << {:name => 'twitter', :value => self.twitter_username} if !self.twitter_username.blank?
      self.external_services << {:name => 'youtube', :value => self.youtube_username} if !self.youtube_username.blank?
      self.external_services << {:name => 'friendfeed', :value => self.friendfeed_username} if !self.friendfeed_username.blank?
      self.external_services << {:name => 'website_url', :value => self.website_url} if !self.website_url.blank?
    end
    
    self.external_services
  end
  
  def receives_each_follow_notification?
    (!self.follow_notification_type.blank? and self.follow_notification_type == FollowNotificationType.EACH) ? true : false
  end
  
  def receives_summary_of_follow_notifications?
    (!self.follow_notification_type.blank? and self.follow_notification_type == FollowNotificationType.SUMMARY) ? true : false
  end
  
  
  def try_to_login
    hashed_password = User.hash_password(self.password || "")
    User.find(:first, :conditions => ["(lower(email) = lower(?) OR lower(username) = lower(?)) AND hashed_password = ? AND feed_owner = false", self.email, self.email, hashed_password])
  end
  
  def register_login!
    self.last_login_at = Time.now
    self.login_count = self.login_count + 1
    self.save
    
    # Users who have logged in twice become "active"
    # Active users get access to the Messaging Layer
    if login_count == 2
      Job.enqueue(:type => JobType.find_by_name('back_activity_generator'), :processable => self)
    end
  end
  
  def self.hash_password(password)
    Digest::SHA1.hexdigest(password)
  end
  
  def self.valid_username?(username)
    if username.length < 4
      return false
    end
    
    if username.length > 15
      return false
    end
    
    if username.match(/\s/)
      return false
    end
    
    if username.match(/\./)
      return false
    end
    
    if !User.unique_username?(username)
      return false
    end
    
    return true
  end
  
  def self.unique_username?(username)
    (username.downcase != 'setup' and User.count(:conditions => ["lower(username) = lower(?)", username]) == 0) ? true : false
  end
  
  def self.valid_email?(email)
    if email.blank?
      return false
    end
    
    if !email.match(/^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/)
      return false
    end
    
    if !User.unique_email?(email)
      return false
    end
    
    return true
  end
  
  def self.unique_email?(email)
    (User.count(:conditions => ["lower(email) = lower(?)", email]) == 0) ? true : false
  end
  
  
  # Relationships and Subscriptions
  def follow(friend, silent = false)
    if !follows?(friend)
      friendship = Friendship.new
      friendship.user_id    = self.id
      friendship.friend_id  = friend.id
      friendship.silent     = silent
      friendship.save
      
      if news_item = friend.last_action
        news_item.generate_message_for_user!(self)
      end
      
      Rails.cache.delete("users/#{self.id}/followings")
      Rails.cache.delete("users/#{self.id}/followings/count")
      Rails.cache.delete("users/#{self.id}/followings/random")
      
      Rails.cache.delete("users/#{self.id}/followers/count")
      Rails.cache.delete("users/#{self.id}/followers/random")
      
      Rails.cache.delete("users/#{self.id}/friends/count")
      Rails.cache.delete("users/#{self.id}/friends/random")
      
      Rails.cache.delete("users/#{friend.id}/followers")
    end
  end
  
  def unfollow(friend)
    if follows?(friend)
      Friendship.find(:first, :conditions => ['user_id = ? AND friend_id = ?', self.id, friend.id]).destroy
      
      Rails.cache.delete("users/#{self.id}/followings")
      Rails.cache.delete("users/#{self.id}/followings/count")
      Rails.cache.delete("users/#{self.id}/followings/random")
      
      Rails.cache.delete("users/#{self.id}/followers/count")
      Rails.cache.delete("users/#{self.id}/followers/random")
      
      Rails.cache.delete("users/#{self.id}/friends/count")
      Rails.cache.delete("users/#{self.id}/friends/random")
      
      Rails.cache.delete("users/#{friend.id}/followers")
    end
  end
  
  def follows?(friend)
    Friendship.count(:all, :conditions => ['user_id = ? AND friend_id = ?', self.id, friend.id]) > 0 ? true : false
  end
  
  
  def subscribe_to(channel, silent = false)
    if !subscribes_to?(channel)
      subscription = Subscription.new
      subscription.user_id    = self.id
      subscription.channel_id = channel.id
      subscription.silent     = silent
      subscription.save
      
      Rails.cache.delete("users/#{self.id}/subscriptions")
      Rails.cache.delete("users/#{self.id}/subscriptions/count")
      Rails.cache.delete("users/#{self.id}/subscriptions/random")
      Rails.cache.delete("users/#{self.id}/subscribed_channels")
    end
  end
  
  def unsubscribe_from(channel)
    if subscribes_to?(channel)
      Subscription.find(:first, :conditions => ['user_id = ? AND channel_id = ?', self.id, channel.id]).destroy
      
      Rails.cache.delete("users/#{self.id}/subscriptions")
      Rails.cache.delete("users/#{self.id}/subscribed_channels")
    end
  end
  
  def subscribes_to?(channel)
    count = Rails.cache.fetch("subscription/user/#{self.id}/channel/#{channel.id}/status", :expires_in => 1.week) do
      Subscription.count(:all, :conditions => ['user_id = ? AND channel_id = ?', self.id, channel.id])
    end
    
    (count > 0)
  end
  
  
  def followings(*args)
    # Speed this method up with cache
    options = args.extract_options!
    User.followings_of(self).all(options)
  end
  
  def followers(*args)
    # Speed this method up with cache
    options = args.extract_options!
    User.followers_of(self).all(options)
  end
  
  def friends(*args)
    options = args.extract_options!
    User.friends_of(self).all(options)
  end
  
  def recommended(*args)
    # Speed this method up with cache
    options = args.extract_options!
    
    if friendship = Friendship.by_user(self).first(:order => 'created_at DESC') and friendship.created_at
      User.member_since_at_least(friendship.created_at).all(options)
    else
      User.member_since_at_least((Rails.env.production? ? 2.weeks.ago : 6.months.ago)).except(self.followings_ids).all(options)
    end
  end
  
  def subscribed_channels(*args)
    # Speed this method up with cache
    options = args.extract_options!
    
    if !self.id.blank?
      Channel.subscribed_to_by(self).all(options)
    else
      Channel.suggested.all(options)
    end
  end
  
  def contacts(*args)
    # Speed this method up with cache
    options = args.extract_options!
    Contact.of_user(self).all(options)
  end
  
  
  # Streams
  def activity(*args)
    # Speed and clean this method up with the caching system
    options = args.extract_options!
    
    if self.consumes_grouped_activity?
      NewsItem.grouped_activity([self.id], options)
    else
      NewsItem.ungrouped_activity([self.id], options)
    end
  end
  
  def last_action
    NewsItem.by_user(self).first(:order => 'created_at DESC')
  end
  
  
  def followings_ids
    # Speed this method up with cache
    if !self.id.blank?
      Rails.cache.fetch("users/#{self.id}/followings", :expires_in => 1.week) do
        self.friendships.collect{|friendship| friendship.friend_id}
      end
    else
      User.default_followings.collect{|user| user.id}
    end
  end
  
  def followings_activity(*args)
    options = args.extract_options!
    
    if Parameter.status?('messaging_layer_enabled') and self.active?
      user = (self.id.blank? ? User.default_user : self)
      
      if self.consumes_grouped_activity?
        activity_messages = ActivityMessage.for_user(user).grouped.recent.all(options)
      else
        activity_messages = ActivityMessage.for_user(user).recent.all(options)
      end
      
      return Util::Cache.collect_news_items_from_activity_messages(activity_messages)
    else
      user_ids = self.followings_ids.collect{|user_id| user_id}
      if !self.id.blank? and (options[:include_self].nil? ? true : options[:include_self])
        user_ids << self.id
      end
      options.delete(:include_self)
      
      if self.consumes_grouped_activity?
        news_items = NewsItem.grouped_activity(user_ids, options)
      else
        news_items = NewsItem.ungrouped_activity(user_ids, options)
      end

      return Util::Cache.collect_news_items(news_items)
    end
  end
  
  def followings_comments(*args)
    # Speed and clean this method up with the caching system
    options = args.extract_options!
    
    user_ids = self.followings_ids
    if !self.id.blank? and (options[:include_self].nil? ? true : options[:include_self])
      user_ids << self.id
    end
    options.delete(:include_self)
    
    Comment.for_commentable_type('Video').by_users(user_ids).in_reverse_order.all(options)
  end
  
  
  def subscription_ids
    # Speed this method up with cache
    if !self.id.blank?
      Rails.cache.fetch("users/#{self.id}/subscriptions", :expires_in => 1.week) do
        self.subscriptions.collect{|subscription| subscription.channel_id}
      end
    else
      Channel.default_subscriptions.collect{|channel| channel.id}
    end
  end
  
  def subscription_videos(*args)
    # Speed and clean this method up with the caching system
    options = args.extract_options!
    max_id = options.delete(:max_id)
    
    if max_id.nil?
      saved_videos = SavedVideo.in_channels(self.subscription_ids).all(options)
      max_id = saved_videos.first.id if saved_videos.size > 0
    else
      saved_videos = SavedVideo.in_channels(self.subscription_ids).with_max_id_of(max_id).all(options)
    end
    
    videos = Util::Cache.collect_saved_videos(saved_videos)
    
    return videos, max_id
  end
  
  # ActivityMessages
  def generate_messages!
    NewsItem.find(:all, :conditions => ['user_id IN (?) AND created_at > ?', self.followings_ids, 60.days.ago], :order => 'created_at ASC').each do |news_item|
      news_item.generate_message_for_user!(self)
    end
  end
  
  # Utility Methods
  def liked?(video)
    self.cached_likes[video.id.to_s.to_sym]
  rescue
    (Like.by_user(self).for_video(video).count > 0)
  end

  def disliked?(video)
    self.cached_dislikes[video.id.to_s.to_sym]
  rescue
    (Dislike.by_user(self).for_video(video).count > 0)
  end
  
  def cache_like!(like)
    self.cached_likes[like.video_id.to_s.to_sym] = like.video_id
  end
  
  def uncache_like!(like)
    self.cached_likes.delete(like.video_id.to_s.to_sym)
  end

   def cache_dislike!(like)
    self.cached_dislikes[like.video_id.to_s.to_sym] = like.video_id
  end
  
  def uncache_dislike!(like)
    self.cached_dislikes.delete(like.video_id.to_s.to_sym)
  end

  
  def cached_likes
    Rails.cache.fetch("user/#{self.id}/likes", :expires_in => 1.week) do
      CacheableHash.new("user/#{self.id}/likes", :hash => Hash[*Like.by_user(self).collect{|like| [like.video_id.to_s.to_sym, like.video_id]}.flatten], :expires_in => 1.week)
    end
  end

  def cached_dislikes
        Rails.cache.fetch("user/#{self.id}/dislikes", :expires_in => 1.week) do
      CacheableHash.new("user/#{self.id}/dislikes", :hash => Hash[*Dislike.by_user(self).collect{|like| [like.video_id.to_s.to_sym, like.video_id]}.flatten], :expires_in => 1.week)
    end
  end
  
  def self.default_user
    Rails.cache.fetch('users/default-user', :expires_in => 1.week) do
      User.find_by_slug('default')
    end
  end
  
  def self.default_followings
    Rails.cache.fetch('users/default-followings', :expires_in => 1.week) do
      User.members.all(:conditions => {:suggested => true})
    end
  end
  
  def <=>(obj)
    if obj.class == Contact
      self.username.downcase <=> obj.email.downcase
    else
      self.username.downcase <=> obj.username.downcase
    end
  end
end
