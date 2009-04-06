class Admin::ChannelsController < ApplicationController
  around_filter :ensure_user_can_administer
  around_filter :load_channel, :only => [:edit, :update, :feeds]
  layout 'page'
  
  
  def index
    searchable
    setup_pagination(:per_page => 50)
    
    if @q.blank?
      @channels = collect('channels', Channel.public.all(:order => 'created_at DESC', :offset => @offset, :limit => @per_page))
    else
      @channels = Channel.search(@q.split.join(' | '), :page => @page, :per_page => @per_page, :conditions => {:user_owned => false}, :match_mode => :boolean)
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
    end
  end
  
  def feeds
    
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
