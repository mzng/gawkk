class ChannelsController < ApplicationController
  around_filter :load_channel, :only => [:show, :subscribers]
  layout 'page'
  
  # Channel Manager
  def index
    setup_pagination(:per_page => 42)
    
    if params[:t] and params[:t] == 'p'
      @type = 'p'
    else
      @type = 'f'
    end
    
    if params[:s] and params[:s] == 'a'
      @sort = 'a'
      order = 'name ASC'
    else
      @sort = 'p'
      order = 'subscriptions_count DESC'
    end
    
    
    if @type == 'f'
      @channels = collect('channels', Channel.featured.all(:order => order, :offset => @offset, :limit => @per_page))
    else
      @channels = collect('channels', Channel.public.all(:order => order, :offset => @offset, :limit => @per_page))
    end
  end
  
  
  # Streams
  def show
    # load_channel or redirect
    setup_pagination
    setup_channel_sidebar(@channel)

    @videos = collect('saved_videos', @channel.videos(:offset => @offset, :limit => @per_page))
  end
  
  
  # Single Channel
  def subscribers
    # load_channel or redirect
    setup_pagination(:per_page => 42)
    setup_channel_sidebar(@channel)
    
    @users = collect('users_from_subscriptions', Subscription.for_channel(@channel).recent.all(:offset => @offset, :limit => @per_page))
  end
  
  
  # Channel Actions
  def subscribe
    # ensure_logged_in_user or do nothing
    
    if @channel = Channel.find(params[:id])
      logged_in_user.subscribe_to(@channel)
    end
    
    respond_to do |format|
      format.js {}
    end
  end
  
  def unsubscribe
    # ensure_logged_in_user or do nothing
    
    if @channel = Channel.find(params[:id])
      logged_in_user.unsubscribe_from(@channel)
    end
    
    respond_to do |format|
      format.js {
        render :action => "subscribe"
      }
    end
  end
  
  
  private
  def load_channel
    if (@user = User.find_by_slug(params[:user])) and (@channel = Channel.owned_by(@user).with_slug(params[:channel]).first)
      if @user.feed_owner?
        yield
      else
        redirect_to :controller => "users", :action => "activity", :id => @user
      end
    else
      flash[:notice] = 'The channel you are looking for does not exist.'
      redirect_to :action => "index"
    end
  end
  
  def ensure_logged_in_user
    if user_logged_in?
      yield
    else
      render :nothing => true
    end
  end
end
