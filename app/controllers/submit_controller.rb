class SubmitController < ApplicationController
  around_filter :ensure_logged_in_user, :only => [:index, :process_video]
  skip_before_filter :verify_authenticity_token, :only => [:suggest_thumbnails]
  layout 'page'
  
  
  def index
    params[:comment][:body] = '' if params[:comment] and params[:comment][:body] == 'Tell your friends about it.'
    params[:video][:url]    = '' if params[:video] and params[:video][:url] == 'Video URL (optional)'
    
    params[:comment][:body].strip!
    params[:video][:url].strip!
    
    
    if request.post?
      @tweet_it = (params[:tweet][:it] == '1' and logged_in_user.auto_tweet?) ? true : false
      
      if params[:video][:url].blank? or params[:video][:url] == 'Video URL (optional)'
        if !params[:comment][:body].blank?
          NewsItem.report(:type => 'status', :user_id => logged_in_user.id, :message => params[:comment][:body])
        end
        
        redirect_to :controller => "videos", :action => "friends"
      else
        @comment = Comment.new(params[:comment])
        
        @video = Video.new
        @video.url = params[:video][:url].strip
        if (existing_video = Video.find_by_url(@video.url)).nil?
          @video.name = Util::Title.from_url(@video.url)
          @video.slug = Util::Slug.generate(@video.title)
          @video.embed_code = Util::EmbedCode.generate(@video, @video.url)
          
          @categories = Category.all_cached
          @youtube_id = Util::YouTube.extract_id(@video.url)
        else
          # Comment.create
          redirect_to :controller => "videos", :action => "discuss", :id => existing_video
        end
      end
    else
      redirect_to :controller => "videos", :action => "friends"
    end
  end
  
  def process_video
    params[:video][:title]        = '' if params[:video] and params[:video][:title] == 'Title...'
    params[:video][:description]  = '' if params[:video] and params[:video][:description] == 'Description...'
    params[:video][:embed_code]   = '' if params[:video] and params[:video][:embed_code] == 'Embed Code...'
    params[:comment][:body]       = '' if params[:comment] and params[:comment][:body] == 'Comment...'
    
    params[:comment][:body].strip!
    
    
    if request.post?
      if params[:video][:category_id] == 'Select a Category...'
        params[:video][:category_id] = Category.find_by_slug('uncategorized').id
      end
      
      @video = Video.new(params[:video])
      @video.slug = Util::Slug.generate(@video.name)
      @video.description  = @video.name if @video.description.blank?
      @video.description  = Util::Scrub.html(@video.description)
      @video.posted_by_id = logged_in_user.id
      
      @video = Util::Thumbnail.use_suggested_thumbnail(@video)
      
      @comment = Comment.new(params[:comment])
      
      if @video.save
        SavedVideo.create(:channel_id => Channel.owned_by(logged_in_user).first.id, :video_id => @video.id)
        NewsItem.report(:type => 'submit_a_video', :reportable => @video, :user_id => logged_in_user.id)
        
        if !params[:comment][:body].blank?
          @comment.user_id = logged_in_user.id
          @comment.commentable_type = 'Video'
          @comment.commentable_id = @video.id
          @comment.save
          
          if params[:tweet][:it] == '1' and logged_in_user.auto_tweet?
            Tweet.report('make_a_comment', logged_in_user, @comment)
          end
        end
        
        redirect_to :controller => "videos", :action => "friends"
      else
        @categories = Category.all_cached
        render :action => "index"
      end
    else
      redirect_to :controller => "videos", :action => "friends"
    end
  end
  
  def suggest_thumbnails
    @image_keys = Util::Thumbnail.suggest(params[:name], params[:youtube_id])
    
    respond_to do |format|
      format.js {}
    end
  end
  
  private
  def ensure_logged_in_user
    if user_logged_in?
      yield
    else
      flash[:notice] = 'You must be logged in to do that.'
      redirect_to :controller => "videos", :action => "friends"
    end
  end
end
