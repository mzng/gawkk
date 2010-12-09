class VideosController < ApplicationController
  around_filter :ensure_logged_in_user, :only => [:unlike, :edit, :thumbnail_search, :update]
  around_filter :load_video, :only => [:discuss, :share, :watch, :like, :unlike, :dislike, :comment, :edit, :update]
  around_filter :redirect_improper_formats, :only => [:share, :watch, :comment]
  skip_before_filter :verify_authenticity_token, :only => [:watch, :reload_activity, :reload_comments, :comment]
  
  layout 'page'
  
  
  # Streams
  def home
    pitch
    record_ad_campaign
    set_meta_description("Gawkk is like a 'Twitter for videos' where members discover, share and discuss videos from around the web with their friends by answering the question: What are you watching?")
    set_meta_keywords("video,media,sharing,social,social networking,twitter,facebook,news,tv shows,movies,music,funny videos")
    setup_pagination
    
    @categories = Rails.cache.fetch('fp_categories', :expires_in => 1.week) do
      Category.allowed_on_front_page
    end

    @searches = Rails.cache.fetch('fp_searches', :expires_in => 3.hours) do
      StagedSearch.for_front_page
    end

    @base_user = (logged_in_user or User.new)

    @videos = Rails.cache.fetch('fp_videos', :expires_in => 2.hours) do
      ids = Video.popular.allowed_on_front_page.with_max_id_of(@max_id).all(:limit => 18)
      Video.find(ids, :include => [:category, {:posted_by => :channels}, {:saved_videos => {:channel => :user}}], :order => 'promoted_at DESC')
    end
  end
  
    
  def index
    @popular = !params[:newest] 
    
    pitch
    set_feed_url("http://www.gawkk.com/all/#{@popular ? 'popular' : 'newest'}.rss")
    set_title("All Topics")
    setup_pagination(:per_page => (params[:format] == 'rss' ? 100 : 25))
    setup_category_sidebar
    @categories = Rails.cache.fetch("topics", :expires_in => 1.week) do
      Category.all(:order => "name asc")
    end

    @popular_channels = Rails.cache.fetch("topics_channel", :expires_in => 6.hours) do
      ids = Channel.suggested(:order => 'rand()')
      Channel.find(ids, :include => :user)
    end

    @videos = Rails.cache.fetch("topics_#{params[:format] || 'web'}_#{@page}", :expires_in => 2.hours) do
      ids = Video.popular.allowed_on_front_page.with_max_id_of(@max_id).all(:offset => @offset, :limit => @per_page)
      Video.find(ids, :include => [:category, {:posted_by => :channels}, {:saved_videos => {:channel => :user}}], :order => 'promoted_at DESC')
    end
  end
  
  def category
    redirect_to category_path(params[:category]), :status=>301  and return if !request.url =~ /topics/ 
      
    if !params[:category].nil? and @category = Category.find_by_slug(params[:category])
      pitch
      set_feed_url("http://www.gawkk.com/#{@category.slug}/#{@popular ? 'popular' : 'newest'}.rss")
      set_title("Videos in The #{@category.name} Topic")
      
      setup_pagination(:per_page => (params[:format] == 'rss' ? 100 : 15))
      
      @related_channels = Rails.cache.fetch("r_c_#{@category.slug}", :expires_in => 30.minutes) do
        Channel.in_category(@category.id).all(:order => 'rand()', :limit => 30, :include => :user)
      end
 
      @videos = Rails.cache.fetch("c_#{@category.id}_vid", :expires_in => 30.minutes) do
        ids = Video.popular.in_category(@category).all(:limit => @per_page)
        if ids.empty?
          ids = Video.in_category(@category).all(:order => "id desc", :limit => @per_page)
        end

        if ids.empty?
          []
        else
          Video.find(ids, :include => [:category, {:posted_by => :channels}, {:saved_videos => {:channel => :user}}], :order => 'popularity_score desc')
        end
        
      end
    else
      flash[:notice] = 'The category you are looking for does not exist.'
      redirect_to :action => "index", :newest => !@popular
    end
  end

  def category_ref
    render :nothing => true and return if params[:category].nil? || !@category = Category.find(params[:category])
    
    setup_pagination(:per_page => (params[:format] == 'rss' ? 100 : 15))
    @popular = !params[:newest]

    if @popular
      @videos = collect('videos', Video.popular.in_category(@category).all(:offset => @offset, :limit => @per_page))
    else
      @videos = collect('videos', Video.newest.in_category(@category).all(:offset => @offset, :limit => @per_page))
    end

    render :layout => false
  end
  
  def subscriptions
    redirect_to :controller => 'channels'
  end
  
  
  # Single Video
  def follow
    if !params[:id].nil? and params[:id][/%20$/]
      params[:id].gsub(/%20$/, '')
    end
    
    if params[:id] and video = Video.find(Util::BaseConverter.to_base10(params[:id]))
      redirect_to :action => "discuss", :id => video, :nid => params[:nid], :cid => params[:cid], :thread_id => params[:thread_id]
    else
      flash[:notice] = 'The video you are looking for does not exist.'
      redirect_to :action => "index", :popular => false
    end
  end
  
    
  def discuss
    # load_video or redirect
    pitch(:sidebar => true)
    set_meta_description(@video.safe_description.first(156))
    set_meta_keywords(@video.tags.join(','))
    set_title(@video.title)
    set_thumbnail("http://gawkk.com/images/#{@video.thumbnail.blank? ? 'no-image.png' : @video.thumbnail}")
    #setup_category_sidebar(@category)
    setup_related_videos(@video)
    
    if @video.next_videos.blank?
      @parts = nil
    else
      @parts = Video.find(:all, :conditions => "id in (#{@video.next_videos.gsub(' ', ',')})", :order => :id)
    end

    begin
      @tagged = true # (rand(2) == 0)
      @generate_phrases = true
      
      @news_item = nil
      
      if params[:nid] and params[:nid].to_s.match(/^[0-9]+$/)
        if @news_item = NewsItem.find(params[:nid].to_i)
          if @news_item.reportable_type != 'Video' or @news_item.reportable_id != @video.id
            @news_item = nil
          end
        end
      elsif params[:cid] and params[:cid].to_s.match(/^[0-9]+$/)
        if comment = Comment.find(params[:cid].to_i)
          if comment.commentable_type == 'Video' and comment.commentable_id == @video.id
            @news_item = NewsItem.find(:first, :conditions => {:actionable_type => 'Comment', :actionable_id => comment.id})
          end
        end
      end
    rescue
      # Finding an associated NewsItem is not necessary.
    end
    
    @base_user = (logged_in_user or User.new)
    @include_followings = true
  end
  
  def share
    # load_video or redirect
    containerable
  end
  
  def watch
    # load_video or redirect
    affects_recommendation_countdown
    coerce_back_to_js
    containerable
  end
  
  def reload_activity
    containerable
    
    @video = Rails.cache.fetch("videos/#{params[:id]}", :expires_in => 1.day) {
      Video.find(params[:id], :include => [:category, {:saved_videos => {:channel => :user}}])
    }
    @base_user = Rails.cache.fetch("users/#{params[:base_user]}", :expires_in => 1.day) {
      User.find_by_slug(params[:base_user])
    }
    @include_followings = params[:include_followings]
  end
  
  def reload_comments
    containerable
    
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
    containerable
    
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

  def dislike
    affects_recommendation_countdown
    containerable
    
    like = Dislike.new
    like.video_id = @video.id
    
    if user_logged_in?
      like.user_id = logged_in_user.id
      like.save
    else
      session[:actionable] = like
      
      @user = User.new
      @user.send_digest_emails = true
      render :template => 'registration/register' and return
    end

    render 'like'
  end
  
  def unlike
    affects_recommendation_countdown
    containerable
    
    # load_video or redirect
    if like = Like.by_user(logged_in_user).for_video(@video).first
      like.destroy
    end
    if dislike = Dislike.by_user(logged_in_user).for_video(@video).first
      dislike.destroy
    end
    render :action => 'like'
  end
  
  def comment
    # load_video or redirect
    containerable
    
    @comment = Comment.new
    
    if params[:reply_id] and params[:reply_id] != '' and @reply = Comment.find(params[:reply_id])
      @comment.thread_id = @reply.thread_id
      @explicit_reply = (!params[:explicit_reply].blank? and params[:explicit_reply] == 'true') ? true : false
    else
      @explicit_reply = false
    end
  end
  
  def edit
    containerable
    
    @categories = Category.all_cached
  end
  
  def thumbnail_search
  end
  
  def thumbnail_search_control
    render :layout => false
  end
  
  def update
    containerable
    
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
    if params[:id] and @video = Rails.cache.fetch("videos/#{params[:id].first(225)}", :expires_in => 1.day) {Video.find_by_slug(params[:id], :include => [:category, {:saved_videos => {:channel => :user}}])}
      yield
    else
      flash[:notice] = 'The video you are looking for does not exist.'
      redirect_to :action => "index", :newest => false
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
