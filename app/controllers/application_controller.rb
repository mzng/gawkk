# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  include ExceptionNotifiable
  
  before_filter [:preload_models, :delegate_request, :check_cookie, :check_for_invitation, :perform_outstanding_action, :load_subscriptions]
  after_filter  [:remember_facebook_session, :reset_redirect_to]
  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details
  
  # Scrub sensitive parameters from your log
  # filter_parameter_logging :password
  
  private
  
  # Ensures objects can be properly marshaled out of memcached
  def preload_models
    CacheableHash
    Category
    Channel
    Invitation
    NewsItem
    NewsItemType
    SavedVideo
    User
    Video
  end
  
  # Ensure Facebook requests are stateful by overwriting the session method
  def session
    if request_for_facebook?
      # TODO: Confirm _session_id is associated with the proper ip address
      
      request.session[:instantiate_session] = true
      params[:_session_id] = request.session_options[:id] unless params[:_session_id]
      
      Rails.cache.fetch("sessions/#{params[:_session_id]}", :expires_in => 1.week) do
        CacheableHash.new("sessions/#{params[:_session_id]}", :hash => request.session, :expires_in => 1.week)
      end
    else
      request.session
    end
  end
  
  def remember_facebook_session
    session
  end

  # Facebook requests require cookie-less sessions, tag along the _session_id
  def default_url_options(options = nil)
    if request_for_facebook?
      params[:_session_id] = request.session_options[:id] unless params[:_session_id]
      {:_session_id => params[:_session_id]}
    end
  end

  # Requests from Facebook are handled differently, okay?
  def delegate_request
    logger.debug "=================================================================="
    logger.debug " This is a #{request_for_facebook? ? 'Facebook' : 'Regular'} Request"
    logger.debug "------------------------------------------------------------------"
    logger.debug " request.session_options[:id] = #{request.session_options[:id]}"
    logger.debug " params[:_session_id]         = #{params[:_session_id]}"
    logger.debug "------------------------------------------------------------------"
    logger.debug " session.keys = #{session.keys.join(', ')}"
    logger.debug "=================================================================="
    logger.debug ''
    
    if request_for_facebook?
      coerce_into_fbml_or_fbjs
      require_login_for_facebook
    else
      ActionController::Base.asset_host = nil
    end
  end
  
  def request_for_facebook?
    (request.subdomains.first == 'web1' or request.subdomains.first == 'facebook') ? true : false
  end
  
  # We want to use our fbml and fbjs templates if the request is for the facebook application
  def coerce_into_fbml_or_fbjs
    request.format = ((request.format == 'text/javascript') ? :fbjs : :fbml)
  end
  
  # Some ajax requests via facebook will use the standard rjs templates and associated views
  def coerce_back_to_js
    request.format = :js
  end
  
  # The current user should have a FacebookSession and a Gawkk account
  def require_login_for_facebook
    if ensure_authenticated_to_facebook and !user_logged_in?
      if facebook_account = FacebookAccount.find(:first, :conditions => {:facebook_user_id => session[:facebook_session].user.uid.to_s})
        @user = facebook_account.user
        
        # Update the user's last login time
        @user.update_attribute(:cookie_hash, bake_cookie_for(@user))
        @user.register_login!
        
        # Store the logged in user's id in the session
        session[:user_id] = @user.id
      elsif controller_name != 'facebook'
        redirect_to :controller => 'facebook', :action => 'connect'
      end
    end
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
        user.register_login!
      end
    end
  end
  
  def bake_cookie_for(user)
    cookie_pass = [Array.new(9){rand(256).chr}.join].pack("m").chomp
    cookie_hash = Digest::MD5.hexdigest(cookie_pass + user.salt)
    
    cookies[:_gawkk_login] = {:value => [user.slug, cookie_pass], :expires => 3.month.from_now}
    
    return cookie_hash
  end
  
  # Check for an incoming invitee
  def check_for_invitation
    if params[:follow] and params[:i]
      if invitation = Invitation.find(params[:i]) and !invitation.accepted? and invitation.host.slug == params[:follow]
        session[:invitation_id] = invitation.id
      end
    elsif params[:follow]
      if host = User.find_by_slug(params[:follow])
        session[:host_id] = host.id
      end
    end
  end
  
  def outstanding_invitation
    if !session[:invitation_id].blank?
      Rails.cache.fetch("invitations/#{session[:invitation_id]}", :expires_in => 6.hours) do
        Invitation.find(session[:invitation_id])
      end
    elsif !session[:host_id].blank?
      Invitation.new(:host_id => session[:host_id])
    else
      return nil
    end
  end
  
  def accept_outstanding_invitation
    if user_logged_in? and outstanding_invitation
      if !session[:invitation_id].blank?
        Invitation.find(outstanding_invitation.id).accepted_by(logged_in_user)
        session[:invitation_id] = nil
      elsif !session[:host_id].blank?
        logged_in_user.follow(User.find(session[:host_id]))
        session[:host_id] = nil
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
  
  def reset_redirect_to
    session[:redirect_to] = nil unless action_name == 'login' or action_name == 'oauth_request' or action_name == 'fb_callback'
  end
  
  def load_subscriptions
    if user_logged_in?
      @subscribed_channels = Rails.cache.fetch("users/#{logged_in_user.id.to_s}/subscribed_channels", :expires_in => 12.hours) do
        collect('channels', logged_in_user.subscribed_channels(:order => 'channels.name ASC'))
      end
    else
      @subscribed_channels = Rails.cache.fetch("users/default/subscribed_channels", :expires_in => 24.hours) do
        collect('channels', User.new.subscribed_channels(:order => 'channels.name ASC'))
      end
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
    elsif object.class == Comment
      if user_logged_in? and (user_can_administer? or object.user_id == logged_in_user.id)
        return true
      end
    elsif object.class == NewsItem
      if user_logged_in? and (user_can_administer? or object.user_id == logged_in_user.id)
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
  def layout_based_on_format
    (params[:format] and params[:format] == 'fbml') ? 'facebook' : 'page'
  end
  
  def record_ad_campaign
    if !params[:ref].blank?
      session[:ref] = params[:ref]
    end
  end
  
  def pitch(options = {})
    @pitch_title = (options[:title].blank? ? 'Welcome to Gawkk!' : options[:title])
    
    if options[:sidebar]
      @pitch_sidebar = true
    else
      @pitch = true
    end
  end
  
  def containerable
    @container_id = params[:container_id].nil? ? '' : params[:container_id]
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
  
  def affects_recommendation_countdown
    if !session[:recommendation_countdown].nil?
      session[:recommendation_countdown] = session[:recommendation_countdown] - 1
    else
      session[:recommendation_countdown] = 0
    end
  end
  
  def set_feed_url(feed_url)
    @feed_url = feed_url
  end
  
  def set_meta_description(description)
    @meta_description = description
  end
  
  def set_meta_keywords(keywords)
    @meta_keywords = keywords
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
    @max_id   = params[:max_id]
    @per_page = options[:per_page].nil? ? 25 : options[:per_page]
    
    parse_page
    
    @offset = (@page - 1) * @per_page
  end
  
  def setup_generic_sidebar
    setup_category_sidebar
    
    @featured_channels = Rails.cache.fetch("channels/featured/random", :expires_in => 6.hours) do
      collect('channels', Channel.featured.all(:order => 'rand()', :limit => 16))
    end
    
    @featured_channels = @featured_channels.rand(6)
  end
  
  def setup_recommendation_sidebar
    if user_logged_in? and (session[:recommendation_countdown].blank? or session[:recommendation_countdown] < 1)
      @recommended_users = collect('users', logged_in_user.recommended(:order => 'rand()', :limit => 4))
      
      session[:recommendation_countdown] = 0
      session[:recommendations] = @recommended_users.collect{|user| user.id}
    end
  end
  
  def setup_user_sidebar(user)
    @followings_count = Rails.cache.fetch("users/#{user.id}/followings/count", :expires_in => 6.hours) do
      User.followings_of(user).count
    end
    
    @followings = Rails.cache.fetch("users/#{user.id}/followings/random", :expires_in => 6.hours) do
      user.followings(:order => 'rand()', :limit => 16)
    end
    
    @followings = @followings.rand(10)
    
    
    @followers_count = Rails.cache.fetch("users/#{user.id}/followers/count", :expires_in => 6.hours) do
      User.followers_of(user).count
    end
    
    @followers = Rails.cache.fetch("users/#{user.id}/followers/random", :expires_in => 6.hours) do
      user.followers(:order => 'rand()', :limit => 16)
    end
    
    @followers = @followers.rand(10)
    
    
    @friends_count = Rails.cache.fetch("users/#{user.id}/friends/count", :expires_in => 6.hours) do
      User.friends_of(user).count
    end
    
    @friends = Rails.cache.fetch("users/#{user.id}/friends/random", :expires_in => 6.hours) do
      user.friends(:order => 'rand()', :limit => 16)
    end
    
    @friends = @friends.rand(10)
    
    
    activity_types = Rails.cache.fetch("news_item_types/activity/set", :expires_in => 6.hours) do
      NewsItemType.find(:all, :conditions => ['kind = ?', 'about a user']).collect{|type| type.id}
    end
    
    @posts_count = Rails.cache.fetch("users/#{user.id}/activity/count", :expires_in => 6.hours) do
      NewsItem.count(:all, :conditions => ['news_item_type_id IN (?) AND user_id = ?', activity_types, user.id])
    end
  end
  
  def setup_category_sidebar(category = nil)
    if !category.nil?
      @related_channels = collect('channels', Channel.in_category(category.id).all(:order => 'rand()', :limit => 9))
    else
      @popular_channels = Rails.cache.fetch("channels/popular/random", :expires_in => 6.hours) do
        collect('channels', Channel.suggested(:order => 'rand()'))
      end

      @popular_channels = @popular_channels.rand(9)
    end
    
    @categories = Category.allowed_on_front_page
    @popular_categories = Category.popular_cached
  end
  
  def setup_discuss_sidebar(video)
    @related_channels = Rails.cache.fetch("channels/related-to/category/#{video.category_id}", :expires_in => 6.hours) do
      collect('channels', Channel.in_category(video.category.id).all(:order => 'rand()', :limit => 16))
    end
    
    @related_channels = @related_channels.rand(4)
  end
  
  def setup_related_videos(video)
    @q = Util::Scrub.query(video.title, true)
    begin
      @related_videos = Video.search(@q, :order => :posted_at, :sort_mode => :desc, :per_page => 4, :conditions => {:category_id => Category.allowed_on_front_page_ids}, :retry_stale => true)
    rescue
      @related_videos = Array.new
    end
    
    @channel = video.first_channel
    if !@channel.nil?
      @channel_videos = Rails.cache.fetch("channels/#{@channel.id}/preview", :expires_in => 6.hours) do
        collect('saved_videos', @channel.videos(:limit => 2))
      end
    else
      @channel_videos = Array.new
    end
    
    @category = video.category
    if !@category.nil?
      @category_videos = Rails.cache.fetch("categories/#{@category.id}/preview", :expires_in => 6.hours) do
        collect('videos', Video.newest.in_category(@category).all(:limit => 2))
      end
    else
      @category_videos = Array.new
    end
  end
  
  def setup_channel_sidebar(channel)
    setup_category_sidebar
    
    @recent_subscribers_count = Subscription.for_channel(channel).count
    @recent_subscribers = collect('users_from_subscriptions', Subscription.for_channel(channel).recent.all(:limit => 4))
    
    @related_channels = collect('channels', Channel.in_category(channel.category).all(:order => 'rand()', :limit => 28))
  end
end
