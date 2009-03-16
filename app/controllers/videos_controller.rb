class VideosController < ApplicationController
  around_filter :ensure_logged_in_user, :only => [:like, :unlike, :comment]
  around_filter :load_video, :only => [:discuss, :watch, :like, :unlike, :comment]
  skip_before_filter :verify_authenticity_token, :only => [:watch, :reload_activity, :comment]
  layout 'page'
  
  
  # Streams
  def index
    setup_pagination
    @popular = params[:popular] ? true : false
    
    if @popular
      @videos = collect('videos', Video.popular.allowed_on_front_page.all(:offset => @offset, :limit => @per_page))
    else
      @videos = collect('videos', Video.newest.allowed_on_front_page.all(:offset => @offset, :limit => @per_page))
    end
  end
  
  def category
    if !params[:category].nil? and @category = Category.find_by_slug(params[:category])
      setup_pagination
      @popular = params[:popular] ? true : false
      
      if @popular
        @videos = collect('videos', Video.popular.in_category(@category).all(:offset => @offset, :limit => @per_page))
      else
        @videos = collect('videos', Video.newest.in_category(@category).all(:offset => @offset, :limit => @per_page))
      end
    else
      flash[:notice] = 'The category you are looking for does not exist.'
      redirect_to :action => "index", :popular => @popular
    end
  end
  
  def friends
    record_ad_campaign
    setup_pagination
    if user_logged_in?
      setup_user_sidebar(logged_in_user)
    else
      @featured_channels = collect('channels', Channel.featured.all(:order => 'rand()', :limit => 8))
    end
    
    @base_user = (logged_in_user or User.new)
    @include_followings = true
    @news_items = collect('news_items', @base_user.followings_activity(:offset => @offset, :limit => @per_page))
  end
  
  def subscriptions
    setup_pagination
    if user_logged_in?
      setup_user_sidebar(logged_in_user)
    else
      @featured_channels = collect('channels', Channel.featured.all(:order => 'rand()', :limit => 8))
    end
    
    @videos = collect('saved_videos', (logged_in_user or User.new).subscription_videos(:offset => @offset, :limit => @per_page))
  end
  
  
  # Single Video
  def follow
    if params[:id] and video = Video.find(Util::BaseConverter.to_base10(params[:id]))
      redirect_to :action => "discuss", :id => video, :thread_id => params[:thread_id]
    else
      flash[:notice] = 'The video you are looking for does not exist.'
      redirect_to :action => "index", :popular => false
    end
  end
  
  def discuss
    # load_video or redirect
  end
  
  def watch
    # load_video or redirect
    
    respond_to do |format|
      format.js {}
    end
  end
  
  def reload_activity
    @video = Rails.cache.fetch("videos/#{params[:id]}", :expires_in => 1.day) {
      Video.find(params[:id], :include => [:category, {:saved_videos => {:channel => :user}}])
    }
    @base_user = Rails.cache.fetch("users/#{params[:user]}", :expires_in => 1.day) {
      User.find_by_slug(params[:base_user])
    }
    @include_followings = params[:include_followings]
    
    respond_to do |format|
      format.js {}
    end
  end
  
  def like
    # load_video or redirect
    if Like.by_user(logged_in_user).for_video(@video).count == 0
      Like.create :user_id => logged_in_user.id, :video_id => @video.id
    end
    
    respond_to do |format|
      format.js {}
    end
  end
  
  def unlike
    # load_video or redirect
    if like = Like.by_user(logged_in_user).for_video(@video).first
      like.destroy
    end
    
    respond_to do |format|
      format.js {
        render :action => "like"
      }
    end
  end
  
  def comment
    # load_video or redirect
    @comment = Comment.new
    
    if params[:reply_id] and params[:reply_id] != '' and @reply = Comment.find(params[:reply_id])
      @comment.thread_id = @reply.thread_id
    end
    
    respond_to do |format|
      format.js {}
    end
  end
  
  
  private
  def ensure_logged_in_user
    if user_logged_in?
      yield
    else
      render :nothing => true
    end
  end
  
  def load_video
    if params[:id] and @video = Rails.cache.fetch("videos/#{params[:id].first(225)}", :expires_in => 1.day) {Video.find_by_slug(params[:id])}
      yield
    else
      flash[:notice] = 'The video you are looking for does not exist.'
      redirect_to :action => "index", :popular => false
    end
  end
end
