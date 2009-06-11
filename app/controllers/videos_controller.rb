class VideosController < ApplicationController
  around_filter :ensure_logged_in_user, :only => [:unlike, :edit, :update]
  around_filter :load_video, :only => [:discuss, :share, :watch, :like, :unlike, :comment, :edit, :update]
  around_filter :redirect_improper_formats, :only => [:share, :watch, :comment]
  skip_before_filter :verify_authenticity_token, :only => [:watch, :reload_activity, :reload_comments, :comment]
  layout 'page'
  
  
  # Streams
  def index
    @popular = params[:popular] ? true : false
    
    pitch
    set_feed_url("http://www.gawkk.com/all/#{@popular ? 'popular' : 'newest'}.rss")
    set_title("#{@popular ? 'Popular' : 'Newest'} Videos")
    setup_pagination(:per_page => (params[:format] == 'rss' ? 100 : 25))
    setup_category_sidebar
    taggable
    
    if @popular
      @videos = collect('videos', Video.popular.allowed_on_front_page.all(:offset => @offset, :limit => @per_page))
    else
      @videos = collect('videos', Video.newest.allowed_on_front_page.all(:offset => @offset, :limit => @per_page))
    end
  end
  
  def category
    if !params[:category].nil? and @category = Category.find_by_slug(params[:category])
      @popular = params[:popular] ? true : false
      
      pitch
      set_feed_url("http://www.gawkk.com/#{@category.slug}/#{@popular ? 'popular' : 'newest'}.rss")
      set_title("#{@popular ? 'Popular' : 'Newest'} Videos in The #{@category.name} Category")
      setup_pagination(:per_page => (params[:format] == 'rss' ? 100 : 25))
      setup_category_sidebar(@category)
      taggable
      
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
    pitch
    record_ad_campaign
    set_meta_description("Gawkk is like a 'Twitter for videos' where members discover, share and discuss videos from around the web with their friends by answering the question: What are you watching?")
    set_meta_keywords("video,media,sharing,social,social networking,twitter,facebook,news,tv shows,movies,music,funny videos")
    setup_pagination
    setup_generic_sidebar
    setup_recommendation_sidebar
    setup_user_sidebar(logged_in_user) if user_logged_in?
    
    @base_user = (logged_in_user or User.new)
    @include_followings = true
    @news_items = collect('news_items', @base_user.followings_activity(:offset => @offset, :limit => @per_page))
  end
  
  def subscriptions
    pitch
    setup_pagination
    setup_generic_sidebar
    setup_user_sidebar(logged_in_user) if user_logged_in?
    
    saved_videos = (logged_in_user or User.new).subscription_videos(:max_id => @max_id, :offset => @offset, :limit => @per_page)
    
    if @page == 1 and saved_videos.size > 0
      @max_id = saved_videos.first.id
    end
    
    @videos = collect('saved_videos', saved_videos)
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
    pitch
    set_meta_description(@video.safe_description.first(156))
    set_meta_keywords(@video.tags.join(','))
    set_title(@video.title)
    set_thumbnail("http://gawkk.com/images/#{@video.thumbnail.blank? ? 'no-image.png' : @video.thumbnail}")
    setup_discuss_sidebar(@video)
    setup_related_videos(@video)
  end
  
  def share
    # load_video or redirect
  end
  
  def watch
    # load_video or redirect
    affects_recommendation_countdown
  end
  
  def reload_activity
    @video = Rails.cache.fetch("videos/#{params[:id]}", :expires_in => 1.day) {
      Video.find(params[:id], :include => [:category, {:saved_videos => {:channel => :user}}])
    }
    @base_user = Rails.cache.fetch("users/#{params[:base_user]}", :expires_in => 1.day) {
      User.find_by_slug(params[:base_user])
    }
    @include_followings = params[:include_followings]
  end
  
  def reload_comments
    @video = Rails.cache.fetch("videos/#{params[:id]}", :expires_in => 1.day) {
      Video.find(params[:id], :include => [:category, {:saved_videos => {:channel => :user}}])
    }
    @base_user = Rails.cache.fetch("users/#{params[:base_user]}", :expires_in => 1.day) {
      User.find_by_slug(params[:base_user])
    }
    @include_followings = params[:include_followings]
  end
  
  def like
    affects_recommendation_countdown
    
    like = Like.new
    like.video_id = @video.id
    
    if user_logged_in?
      like.user_id = logged_in_user.id
      like.save
    else
      session[:actionable] = like
      
      @user = User.new
      @user.send_digest_emails = true
      render :template => 'registration/register'
    end
  end
  
  def unlike
    affects_recommendation_countdown
    
    # load_video or redirect
    if like = Like.by_user(logged_in_user).for_video(@video).first
      like.destroy
    end
    
    render :action => 'like'
  end
  
  def comment
    # load_video or redirect
    @comment = Comment.new
    
    if params[:reply_id] and params[:reply_id] != '' and @reply = Comment.find(params[:reply_id])
      @comment.thread_id = @reply.thread_id
    end
  end
  
  def edit
    # load_video or redirect
    @categories = Category.all_cached
  end
  
  def update
    # load_video or redirect
    params[:video][:embed_code]     = '' if params[:video] and params[:video][:embed_code] == 'Embed Code...'
    params[:thumbnail][:for_video]  = '' if params[:thumbnail] and params[:thumbnail][:for_video] == 'Enter a Thumbnail URL...'
    
    if request.put? and user_can_edit?(@video)
      @video = Video.find(@video.id)
      
      @video.name = params[:video][:name]
      @video.description  = params[:video][:description]
      @video.description  = @video.name if @video.description.blank?
      @video.description  = Util::Scrub.html(@video.description)
      @video.category_id  = params[:video][:category_id]
      @video.embed_code   = params[:video][:embed_code]
      
      @video.save
      
      if params[:thumbnail] and !params[:thumbnail][:for_video].blank?
        Util::Thumbnail.use_url_thumbnail(@video, params[:thumbnail][:for_video])
      end
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
  
  def redirect_improper_formats
    begin
      yield
    rescue ActionView::MissingTemplate
      redirect_to :action => "discuss", :id => @video
    end
  end
end
