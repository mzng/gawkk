class UsersController < ApplicationController
  around_filter :load_member, :only => [:activity, :profile, :comments, :follows, :followers, :friends, :subscriptions, :digest]
  around_filter :ensure_logged_in_user, :only => [:follow, :unfollow, :follow_recommendations, :dismiss_recommendations, :my_videos]
  layout 'page'
  
  # User Manager
  def index
    searchable
    setup_pagination(:per_page => 42)
    
    if params[:s] and params[:s] == 'a'
      @sort = 'a'
      order = 'username ASC'
    else
      @sort = 'l'
      order = 'last_login_at DESC'
    end
    
    @users = collect('users', User.members.all(:order => order, :offset => @offset, :limit => @per_page))
  end
  
  
  # User Pages
  def activity
    if @user.feed_owner?
      redirect_to channel_path @user, @user.channels.first, :status => 301 and return
    else
      redirect_to root_path and return
    end
    # load_member or redirect
    pitch(:title => "Hi there! #{@user.username} is using Gawkk.")
    set_title(@user.username + ' - Activity')
    setup_pagination
    setup_user_sidebar(@user)
    
    @base_user = @user
    @include_followings = false
    @news_items = collect('news_items', @user.activity(:offset => @offset, :limit => @per_page))
  end

  def my_videos
    pitch(:title => "Your Videos")
    set_title("Your Videos")
    setup_pagination
    setup_user_sidebar(logged_in_user)
    @user = logged_in_user
    @base_user = @user
    @include_followings = false
    @videos = Video.find(:all, :conditions => { :posted_by_id => @user.id }, :offset => @offset, :limit => @per_page)
  end
  
  def comments
    # load_member or redirect
    set_title(@user.username + ' - Comments')
    setup_user_sidebar(@user)
  end
  
  def follows
    # load_member or redirect
    set_title(@user.username + ' - Follows')
    setup_pagination(:per_page => 42)
    setup_user_sidebar(@user)
    
    @users = @user.followings(:order => 'users.username ASC', :offset => @offset, :limit => @per_page)
  end
  
  def followers
    # load_member or redirect
    set_title(@user.username + ' - Followers')
    setup_pagination(:per_page => 42)
    setup_user_sidebar(@user)
    
    @users = @user.followers(:order => 'users.username ASC', :offset => @offset, :limit => @per_page)
  end
  
  def friends
    # load_member or redirect
    set_title(@user.username + ' - Friends')
    setup_pagination(:per_page => 42)
    setup_user_sidebar(@user)
    
    @users = @user.friends(:order => 'users.username ASC', :offset => @offset, :limit => @per_page)
  end
  
  def subscriptions
    # load_member or redirect
    set_title(@user.username + ' - Subscriptions')
    setup_user_sidebar(@user)
    
    if user_logged_in? and logged_in_user.id == @user.id
      @channels = subscribed_channels
    else
      @channels = collect('channels', @user.subscribed_channels(:order => 'channels.name ASC'))
    end
  end
  
  def digest
    # load_member or redirect
    @path = Rails.env.production? ? 'http://gawkk.com' : 'http://refactor.local'
    render :text => DigestMailer.create_activity(@user).body, :layout => false
  end
  
  
  # User Actions
  def follow
    # ensure_logged_in_user or do nothing
    coerce_back_to_js
    
    if @friend = User.find_by_slug(params[:id])
      logged_in_user.follow(@friend)
    end
    
    respond_to do |format|
      format.js {}
    end
  end
  
  def unfollow
    # ensure_logged_in_user or do nothing
    coerce_back_to_js
    
    if @friend = User.find_by_slug(params[:id])
      logged_in_user.unfollow(@friend)
    end
    
    respond_to do |format|
      format.js {
        render :action => "follow"
      }
    end
  end
  
  
  # Recommended User Actions
  def follow_recommendations
    # ensure_logged_in_user or do nothing
    
    if !session[:recommendations].nil?
      User.with_ids(session[:recommendations]).all.each do |user|
        logged_in_user.follow(user)
      end
    end
    
    session[:recommendation_countdown] = 5
    
    render :nothing => true
  end
  
  def dismiss_recommendations
    # ensure_logged_in_user or do nothing
    
    session[:recommendation_countdown] = 5
    
    redirect_to '/'
  end
  
  
  private
  def load_user
    if @user = User.find_by_slug(params[:id])
      yield
    else
      flash[:notice] = 'The user you are looking for does not exist.'
      redirect_to :action => "index"
    end
  end
  
  def load_member
    if params[:id] == 'members' or params[:id] == 'default'
      params[:id] = nil
    end
    
    if params[:id].blank? and user_logged_in?
      redirect_to :action => params[:action], :id => logged_in_user
    else
      if @user = User.find_by_slug(params[:id])
        if @user.feed_owner?
          redirect_to channel_path(:user => @user, :channel => @user.channels.first), :status => 301
        else
          redirect_to root_path 
        end
      else
        flash[:notice] = 'The user you are looking for does not exist.'
        redirect_to :action => "index"
      end
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
