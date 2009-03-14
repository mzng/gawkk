class UsersController < ApplicationController
  around_filter :load_member, :only => [:activity, :profile, :comments, :follows, :followers, :friends, :subscriptions]
  layout 'page'
  
  # User Manager
  def index
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
    # load_member or redirect
    setup_pagination
    setup_user_sidebar(@user)
    
    @base_user = @user
    @include_followings = false
    @news_items = @user.activity(:offset => @offset, :limit => @per_page)
  end
  
  def profile
    # load_member or redirect
    setup_user_sidebar(@user)
  end
  
  def comments
    # load_member or redirect
    setup_user_sidebar(@user)
  end
  
  def follows
    # load_member or redirect
    setup_pagination(:per_page => 42)
    setup_user_sidebar(@user)
    
    @users = @user.followings(:order => 'users.username ASC', :offset => @offset, :limit => @per_page)
  end
  
  def followers
    # load_member or redirect
    setup_pagination(:per_page => 42)
    setup_user_sidebar(@user)
    
    @users = @user.followers(:order => 'users.username ASC', :offset => @offset, :limit => @per_page)
  end
  
  def friends
    # load_member or redirect
    setup_pagination(:per_page => 42)
    setup_user_sidebar(@user)
    
    @users = @user.friends(:order => 'users.username ASC', :offset => @offset, :limit => @per_page)
  end
  
  def subscriptions
    # load_member or redirect
    setup_pagination(:per_page => 42)
    setup_user_sidebar(@user)
    
    @channels = @user.subscribed_channels(:order => 'channels.name ASC', :offset => @offset, :limit => @per_page)
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
    if @user = User.find_by_slug(params[:id])
      if !@user.feed_owner?
        yield
      else
        redirect_to channel_path(:user => @user, :channel => @user.channels.first)
      end
    else
      flash[:notice] = 'The user you are looking for does not exist.'
      redirect_to :action => "index"
    end
  end
end
