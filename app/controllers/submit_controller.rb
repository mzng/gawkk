require 'digest/sha1'

class SubmitController < ApplicationController
  
  def process_post
    @error = false
    
    if params[:comment] and params[:video]
      params[:comment][:body] = '' if params[:comment] and params[:comment][:body] == 'Tell your friends about it.'
      params[:video][:url]    = '' if params[:video] and params[:video][:url] == 'Video URL (optional)'
      
      params[:comment][:body] = '' if params[:comment] and params[:comment][:body] == 'What are you watching?'
      params[:video][:url]    = '' if params[:video] and params[:video][:url] == 'http://'

      params[:comment][:body].strip!
      params[:video][:url].strip!
    end
    
    if request.post?
      @tweet_it = (params[:tweet] and params[:tweet][:it] == '1' and logged_in_user.auto_tweet?) ? true : false
      
      if params[:video][:url].blank?
        # Status update
        
        if !params[:comment][:body].blank?
          if user_logged_in?
            type = NewsItemType.cached_by_name('status')
            @news_item = NewsItem.create :news_item_type_id => type.id, :user_id => logged_in_user.id, :message => params[:comment][:body]
            
            if @tweet_it and Rails.env.production?
              Twitter::Client.configure do |config|
                config.user_agent = 'Gawkk'
                config.application_name = 'gawkk'
                config.application_url = 'http://gawkk.com'
                config.source = 'gawkk'
              end
              
              twitter_account = logged_in_user.twitter_account
              twitter = Twitter::Client.new(:login => twitter_account.username, :password => twitter_account.password)
              twitter.status(:post, @news_item.message)
            end
          else
            session[:actionable] = Hash.new
            session[:actionable][:status] = params[:comment][:body]
            
            @user = User.new
            @user.send_digest_emails = true
            render :template => 'registration/register'
          end
        end
      else
        # Post a video
        if !params[:comment][:body].blank?
          @comment = Comment.new(params[:comment])
          @comment.commentable_type = 'Video'
        else
          @comment = nil
        end
        
        @video = Video.new
        @video.url = params[:video][:url].strip
        @video.url = Util::Scrub.url(@video.url) if !@video.url.blank?
        
        if (existing_video = Video.find_by_hashed_url(Digest::SHA2.hexdigest(@video.url.nil? ? '' : @video.url))).nil?
          # Post a new video
          
          @video.name = Util::Title.from_url(@video.url)
          @video.slug = Util::Slug.generate(@video.title)
          @video.description  = @video.title
          @video.embed_code   = Util::EmbedCode.generate(@video, @video.url)
          @video.category_id  = Category.find_by_slug('uncategorized').id
          
          if user_logged_in?
            begin
              @video = Util::Thumbnail.suggest(@video)
              @existing = false
            rescue
              @video = nil
              @error = true
            end
          else
            session[:actionable] = Hash.new
            session[:actionable][:video] = @video
            session[:actionable][:comment] = @comment
            
            @user = User.new
            @user.send_digest_emails = true
            render :template => 'registration/register'
          end
          
        elsif !@comment.nil?
          # Comment on a video we already have
          
          @video = existing_video
          @comment.commentable_id = @video.id
          
          if user_logged_in?
            @comment.user_id = logged_in_user.id
            @comment.twitter_username = logged_in_user.twitter_account.username if @tweet_it
            
            if @comment.save and @tweet_it
              Tweet.report('make_a_comment', logged_in_user, @comment)
            end
            
            @existing = true
          else
            session[:actionable] = @comment

            @user = User.new
            @user.send_digest_emails = true
            render :template => 'registration/register'
          end
        else
          # Like a video we already have
          
          @video = existing_video
          
          like = Like.new
          like.video_id = @video.id

          if user_logged_in?
            like.user_id = logged_in_user.id
            like.save
            
            @existing = true
          else
            session[:actionable] = like

            @user = User.new
            @user.send_digest_emails = true
            render :template => 'registration/register'
          end
        end
      end
    else
      render :nothing => true
    end
  rescue SocketError
    @error = true
    render :nothing => true
  rescue Errno::ENOENT
    @error = true
    render :nothing => true
  end
  
  def complete
    params[:comment][:body]     = '' if params[:comment] and params[:comment][:body] == 'What are you watching?'
    params[:video][:embed_code] = '' if params[:video] and params[:video][:embed_code] == 'Enter embed code...'
    
    if user_logged_in? and request.post?
      @video = Video.new(params[:video])
      
      if (existing_video = Video.find_by_hashed_url(Digest::SHA2.hexdigest(@video.url.nil? ? '' : @video.url))).nil?
        @video.posted_by_id = logged_in_user.id
        if @video.save
          if channels = Channel.owned_by(logged_in_user) and channels.size > 0
            SavedVideo.create(:channel_id => channels.first.id, :video_id => @video.id)
          end
          NewsItem.report(:type => 'submit_a_video', :reportable => @video, :user_id => logged_in_user.id)
          
          if !params[:thumbnail][:for_video].blank?
            Util::Thumbnail.use_url_thumbnail(@video, params[:thumbnail][:for_video])
          else
            @video = Util::Thumbnail.use_suggested_thumbnail(@video)
            @video.save
          end
          
          if params[:comment] and !params[:comment][:body].blank?
            @comment = Comment.new
            @comment.body = params[:comment][:body]
            @comment.commentable_type = 'Video'
            @comment.commentable_id   = @video.id
            @comment.user_id = logged_in_user.id
            @comment.twitter_username = logged_in_user.twitter_account.username if @tweet_it
            
            if @comment.save and (params[:tweet] and params[:tweet][:it] == '1' and logged_in_user.auto_tweet?)
              Tweet.report('make_a_comment', logged_in_user, @comment)
            end
          end
        end
        
        @existing = false
      else
        @video = existing_video
        @existing = true
      end
    elsif !user_logged_in?
      flash[:notice] = 'You must be logged in to do that.'
      redirect_to '/'
    end
  end
  
  def cancel
    
  end
end
