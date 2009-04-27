class Admin::FeedsController < ApplicationController
  around_filter :ensure_user_can_administer
  around_filter :load_channel
  around_filter :load_feed, :only => [:edit, :update, :destroy]
  layout 'page'
  
  
  def new
    @categories = Category.all_cached
    
    @feed = Feed.new
    @feed.active = true
  end
  
  def create
    @feed = Feed.new(params[:feed])
    @feed.owned_by_id = @user.id
    
    if @feed.save
      flash[:notice] = 'The feed was successfully created.'
      redirect_to :controller => 'admin/channels', :action => 'feeds', :id => @channel.id
    else
      @categories = Category.all_cached
      render :action => 'new'
    end
  end
  
  def edit
    @categories = Category.all_cached
  end
  
  def update
    if @feed.update_attributes(params[:feed])
      flash[:notice] = 'The feed was successfully updated.'
      redirect_to :controller => 'admin/channels', :action => 'feeds', :id => @channel.id
    else
      @categories = Category.all_cached
      render :action => 'edit'
    end
  end
  
  def destroy
    @feed.destroy
    
    flash[:notice] = 'The feed was successfully destroyed.'
    redirect_to :controller => 'admin/channels', :action => 'feeds', :id => @channel.id
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
    if @channel = Channel.find(params[:channel_id]) and @user = @channel.user
      yield
    else
      redirect_to :controller => 'admin/channels'
    end
  end
  
  def load_feed
    if @feed = Feed.find(params[:id])
      yield
    else
      redirect_to :controller => 'admin/channels', :action => 'feeds', :id => @channel.id
    end
  end
end
