class Admin::ChannelsController < ApplicationController
  around_filter :ensure_user_can_administer
  around_filter :load_channel, :only => [:edit, :update, :feeds, :feature, :unfeature, :search_only, :destroy]
  layout 'page'
  
  
  def index
    searchable
    setup_pagination(:per_page => 50)
    
    if @q.blank?
      @channels = collect('channels', Channel.public.all(:order => 'name ASC', :offset => @offset, :limit => @per_page))
    else
      @channels = Channel.search(@q.split.join(' | '), :page => @page, :per_page => @per_page, :conditions => {:user_owned => false}, :match_mode => :boolean, :retry_stale => true)
    end
  end
  
  def new
    @user = User.new
  end
  
  def create
    @user = User.new(params[:user])
    @user.administrator = false
    @user.feed_owner    = true
    @user.email         = "feed-owner+#{Util::Slug.generate(@user.username, false)}@gawkk.com"
    @user.password      = Util::AuthCode.generate
    @user.password_confirmation = @user.password
    
    if @user.save
      redirect_to :action => 'edit', :id => (@user.reload).channels.first.id
    else
      render :action => 'new'
    end
  end
  
  def edit
    
  end
  
  def update
    if params[:avatar] and params[:avatar][:for_user] != nil and params[:avatar][:for_user].class != String
      Util::Avatar.use_file_avatar(@user, params[:avatar][:for_user])
    end
    
    if @user.update_attribute('description', params[:user][:description]) and @channel.update_attributes(params[:channel])
      flash[:notice] = 'The channel was successfully updated.'
      redirect_to channel_path(:user => @user, :channel => @channel)
    else
      render :action => 'edit'
    end
  end
  
  def feeds
    @feeds = Feed.find(:all, :conditions => {:owned_by_id => @channel.user_id})
  end
  
  def feature
    @channel.update_attribute('featured', true)
  end
  
  def unfeature
    @channel.update_attribute('featured', false)
    
    render :action => "feature"
  end
  
  def search_only
    @user.feeds.each do |feed|
      feed.destroy
    end
    
    redirect_to :action => "index", :page => params[:page]
  end
  
  def destroy
    if default_user = User.find_by_slug('gawkk')
      if default_channel = default_user.channels.first
        @user.videos.each do |video|
          video.update_attribute(:posted_by_id, default_user.id)
          SavedVideo.create :channel_id => default_channel.id, :video_id => video.id
        end
      end
    end
    
    if @user.destroy
      flash[:notice] = 'The channel was successfully destroyed.'
    else
      flash[:notice] = 'Sorry, but you will have to destroy this channel manually.'
    end
    
    redirect_to :action => "index"
  end
  
  
  private
  def ensure_user_can_administer
    if user_can_administer?
      yield
    else
      redirect_to '/'
    end
  end
  
  def load_channel
    if @channel = Channel.find(params[:id]) and @user = @channel.user
      yield
    else
      redirect_to :action => "index"
    end
  end
end
