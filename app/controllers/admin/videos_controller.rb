class Admin::VideosController < ApplicationController
  around_filter :ensure_user_can_administer
  around_filter :load_video, :only => [:update_embed_code, :destroy]
  layout 'page'
  
  
  def update_embed_code
    params[:video][:embed_code] = '' if params[:video] and params[:video][:embed_code] == 'Enter embed code...'
    
    @video.embed_code = Util::EmbedCode.scrub(params[:video][:embed_code], true)
    @video.save
  end
  
  def destroy
    begin
      ActiveRecord::Base.transaction do
        DeletedVideo.create :name => @video.name, :url => @video.url, :truveo_url => @video.truveo_url, :deleted_at => Time.now
        @video.destroy
      end
    rescue Exception => e
      # This is handled by counting on the videos table to see if the video was actually deleted
      logger.debug '! ' + e.to_s
    end
    
    @video_id = @video.id
    @deleted  = (Video.count(:conditions => {:id => @video_id}) == 0) ? true : false
    
    respond_to do |format|
      format.js {}
    end
  end
  
  
  private
  def ensure_user_can_administer
    if user_can_administer?
      yield
    else
      redirect_to '/'
    end
  end
  
  def load_video
    if @video = Video.find_by_slug(params[:id])
      yield
    else
      redirect_to :controller => "/videos"
    end
  end
end
