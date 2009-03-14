# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  before_filter :preload_models
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
  
  def setup_pagination(options = {})
    @per_page = options[:per_page].nil? ? 25 : options[:per_page]
    
    @page = params[:page].blank? ? 1 : params[:page]
    @page = 1 unless @page.to_s.match(/^[0-9]+$/)
    @page = @page.to_i
    
    @offset = (@page - 1) * @per_page
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
end
