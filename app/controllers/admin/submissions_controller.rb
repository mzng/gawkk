class Admin::SubmissionsController < ApplicationController
  around_filter :ensure_user_can_administer
layout 'page'
  def new
    @categories = Category.all
    @channels = Channel.in_category(@categories[0].id)
  end

  def create
    @videos = []
    @svs = []
    params[:link].each_with_index do |link, i|
      next if link.blank?
      found = false
      video = Video.new
      video.url = link
      video.url = Util::Scrub.url(video.url) if !video.url.blank?
      if (existing_video = Video.find_by_hashed_url(Digest::SHA2.hexdigest(video.url.nil? ? '' : video.url))).nil?
        video.name = params[:title].blank? ? Util::Title.from_url(video.url) : params[:title]
        video.description = params[:description].blank? ? video.name : params[:description]
        video.slug = Util::Slug.generate(video.title) ### ? title != name ?
        video.embed_code = Util::EmbedCode.generate(video, video.url)
        video.category_id = params[:category_id]
        video = Util::Thumbnail.suggest(video)
        video.posted_by_id = Channel.find(params[:channel_id]).user_id
        video.save

      else
        video = existing_video
        video.saved_videos.each do |sv|
          found = true and @svs << sv and break if sv.channel_id == params[:channel_id].to_i
        end        
      end
      (@svs << SavedVideo.create(:channel_id => params[:channel_id].to_i, :video_id => video.id)) unless found
      @videos << video
    end

    if @videos.size > 1
      ids = @videos.collect {|v| v.id}

      @svs.each do |sv|
        this_ids = []
        ids.each do |i|
          next if i == sv.video_id
          this_ids << i
        end
        sv.next_videos = this_ids.join(', ')
        sv.save
      end
    end
  end

  def get_channels
    @channels = Channel.in_category(params[:category_id] )
    render :layout => false
  end

  private
  def ensure_user_can_administer
    if user_can_administer?
      yield
    else
      redirect_to '/'
    end
  end
end
