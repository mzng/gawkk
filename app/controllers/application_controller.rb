# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  include ExceptionNotifiable
  
  before_filter [:preload_models, :check_cookie, :perform_outstanding_action]
  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details
  
  # Scrub sensitive parameters from your log
  # filter_parameter_logging :password
  
  # Ensures objects can be properly marshaled out of memcached
  def preload_models
    Category
    Channel
    NewsItem
    NewsItemType
    SavedVideo
    User
    Video
  end
  
  # Check for a remember cookie and autologin
  def check_cookie
    return if session[:user_id]
    
    if cookies[:_gawkk_login]
      user = User.find_by_slug(cookies[:_gawkk_login].split('&')[0])
      return unless user
      cookie_hash = Digest::MD5.hexdigest(cookies[:_gawkk_login].split('&')[1] + user.salt)
      if user.cookie_hash == cookie_hash
        session[:user_id] = user.id
        user.update_attribute('last_login_at', Time.now)
      end
    end
  end
  
  # Perform any outstanding action
  def perform_outstanding_action
    if user_logged_in? and actionable = session[:actionable]
      if actionable.class == Hash
        if actionable[:video]
          video = actionable[:video]
          video.posted_by_id = logged_in_user.id
          
          if video.save
            if channels = Channel.owned_by(logged_in_user) and channels.size > 0
              SavedVideo.create(:channel_id => channels.first.id, :video_id => video.id)
            end
            NewsItem.report(:type => 'submit_a_video', :reportable => video, :user_id => logged_in_user.id)
            
            video = Util::Thumbnail.replace_with_suggestion(video)
            
            if comment = actionable[:comment]
              comment.commentable_id = video.id
              comment.user_id = logged_in_user.id
              comment.save
            end
          end
        elsif actionable[:status]
          type = NewsItemType.cached_by_name('status')
          NewsItem.create :news_item_type_id => type.id, :user_id => logged_in_user.id, :message => actionable[:status]
        end
      else
        actionable.user_id = logged_in_user.id
        actionable.save
      end
      
      session[:actionable] = nil
    end
  end
  
  # Authorization
  def user_can_administer?
    return user_logged_in? && logged_in_user.administrator?
  end
  
  def user_can_modify?(slug)
    return user_logged_in? && ((logged_in_user.slug == slug) || logged_in_user.administrator?)
  end
  
  def logged_in_user
    if user_logged_in?
      Rails.cache.fetch("users/#{session[:user_id]}", :expires_in => 1.week) do
        User.find(session[:user_id])
      end
    else
      return nil
    end
  end
  
  def user_logged_in?
    (session[:user_id] != nil) ? true : false
  end
  
  def user_can_edit?(object)
    if object.class == Video
      if user_logged_in? and (user_can_administer? or object.posted_by_id == logged_in_user.id)
        return true
      end
    elsif object.class == User
      if user_logged_in? and (user_can_administer? or object.id == logged_in_user.id)
        return true
      end
    end
    
    return false
  end
  
  # Caching
  def collect(type, collection)
    Util::Cache.send("collect_#{type}".to_sym, collection)
  end
  
  # Miscellaneous
  def record_ad_campaign
    if !params[:ref].blank?
      session[:ref] = params[:ref]
    end
  end
  
  def searchable(options = {})
    @q = params[:q] ? params[:q] : ''
    
    if options[:convert_tags]
      @q.gsub(/-/, ' ')
    end
    
    if options[:titleize]
      @q = @q.titleize
    end
    
    @q
  end
  
  def taggable(options = {})
    if options[:assume]
      params[:tagged] = true
    end
    
    @tagged = params[:tagged] ? params[:tagged] : nil
  end
  
  def set_feed_url(feed_url)
    @feed_url = feed_url
  end
  
  def set_title(title)
    @title = title
  end
  
  def set_thumbnail(thumbnail_url)
    @thumbnail_url = thumbnail_url
  end
  
  def parse_page
    @page = params[:page].blank? ? 1 : params[:page]
    @page = 1 unless @page.to_s.match(/^[0-9]+$/)
    @page = @page.to_i
  end
  
  def setup_pagination(options = {})
    @per_page = options[:per_page].nil? ? 25 : options[:per_page]
    
    parse_page
    
    @offset = (@page - 1) * @per_page
  end
  
  def setup_generic_sidebar
    setup_category_sidebar
    
    @active_members     = collect('users_from_news_items', NewsItem.grouped_by_user.recent.all(:limit => 4))
    @featured_channels  = collect('channels', Channel.featured.all(:order => 'rand()', :limit => 4))
  end
  
  def setup_user_sidebar(user)
    # Speed this up with caching
    @followings_count = User.followings_of(user).count
    @followings = user.followings(:order => 'rand()', :limit => 4)
    
    @followers_count = User.followers_of(user).count
    @followers = user.followers(:order => 'rand()', :limit => 4)
    
    @friends_count = User.friends_of(user).count
    @friends = user.friends(:order => 'rand()', :limit => 4)
    
    @subscribed_channels_count = Channel.subscribed_to_by(user).count
    @subscribed_channels = user.subscribed_channels(:order => 'rand()', :limit => 4)
    
    activity_types = NewsItemType.find(:all, :conditions => ['kind = ?', 'about a user']).collect{|type| type.id}
    @posts_count = NewsItem.count(:all, :conditions => ['news_item_type_id IN (?) AND user_id = ?', activity_types, user.id])
  end
  
  def setup_category_sidebar(category = nil)
    if !category.nil?
      @related_channels = collect('channels', Channel.in_category(category.id).all(:order => 'rand()', :limit => 4))
    end
    
    @categories = Category.allowed_on_front_page
  end
  
  def setup_discuss_sidebar(video)
    # @channels_count = SavedVideo.count(:conditions => {:video_id => video.id})
    @channels = collect('channels_from_saved_videos', SavedVideo.all(:conditions => {:video_id => video.id}))
    
    # @members_count = Like.count(:conditions => {:video_id => video.id})
    @members = collect('users_from_likes', Like.all(:conditions => {:video_id => video.id}))
    
    if user_logged_in?
      # @friends_count = NewsItem.by_users(logged_in_user.followings_ids).grouped_by_user.count(:conditions => {:reportable_type => 'Video', :reportable_id => video.id})
      @friends = collect('users_from_news_items', NewsItem.by_users(logged_in_user.followings_ids).grouped_by_user.all(:conditions => {:reportable_type => 'Video', :reportable_id => video.id}))
    end
    
    @related_channels = collect('channels', Channel.in_category(video.category.id).all(:order => 'rand()', :limit => 16))
  end
  
  def setup_related_videos(video)
    @q = Util::Scrub.query(video.title, true)
    begin
      @related_videos = Video.search(@q, :order => :posted_at, :sort_mode => :desc, :per_page => 4, :conditions => {:category_id => Category.allowed_on_front_page_ids}, :retry_stale => true)
    rescue
      @related_videos = Array.new
    end
    
    @channel = video.first_channel
    @channel_videos = (@channel.nil? ? Array.new : collect('saved_videos', @channel.videos(:limit => 4)))
    
    @category = video.category
    @category_videos = (@category.nil? ? Array.new : collect('videos', Video.newest.in_category(@category).all(:limit => 4)))
  end
  
  def setup_channel_sidebar(channel)
    setup_category_sidebar
    
    @recent_subscribers_count = Subscription.for_channel(channel).count
    @recent_subscribers = collect('users_from_subscriptions', Subscription.for_channel(channel).recent.all(:limit => 4))
    
    @related_channels = collect('channels', Channel.in_category(channel.category).all(:order => 'rand()', :limit => 28))
  end
end
