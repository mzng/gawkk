class ChannelsController < ApplicationController
  around_filter :load_channel, :only => [:show, :subscribers]
  layout 'page'
  
  # Channel Manager
  def index
    searchable
    setup_pagination(:per_page => 42)
    setup_category_sidebar
    
    conditions  = 'user_owned = false'
    parameters  = Array.new
    
    # Type filter
    if params[:t] and params[:t] == 'a'
      @type = 'a'
    else
      @type = 'f'
      conditions = conditions.concat(' AND featured = true')
    end
    
    # Category filter
    params[:c] ||= 'a'
    @c = params[:c]

    category = nil
    if @c != 'a' and @c.match(/^[0-9]+$/)
      category = Category.find(@c)
      conditions = conditions.concat(' AND (category_ids like ? OR category_ids like ? OR category_ids like ? OR category_ids like ?)')
      parameters = parameters + ["#{category.id}", "#{category.id} %", "% #{category.id}", "% #{category.id} %"]
      @popular = category.popular
    else
      @popular = true
    end
    
    # Order by
    if params[:s] and params[:s] == 'a'
      @sort = 'a'
      order = 'name ASC'
    else
      @sort = 'p'
      order = 'subscriptions_count DESC'
    end
    
    @channels = collect('channels', Channel.all(:conditions => [conditions] + parameters, :order => order, :offset => @offset, :limit => @per_page))
    @count    = Channel.count(:conditions => [conditions] + parameters)
    @entries  = WillPaginate::Collection.new(@page, @per_page, @count)
  end
  
  
  # Streams
  def show
    # load_channel or redirect
    pitch
    set_feed_url("http://www.gawkk.com/#{@user.slug}/#{@channel.slug}.rss")
    set_meta_description(@channel.proper_name + (@user.description.blank? ? '' : ': ' + @user.description))
    set_meta_keywords(@channel.keywords)
    set_title(@channel.proper_name)
    setup_pagination
    setup_category_sidebar
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
