class Admin::SuggestionsController < ApplicationController
  around_filter :ensure_user_can_administer
  around_filter :load_suggestion, :only => [:suggest, :unsuggest]
  layout 'page'
  
  
  def index
    searchable
    
    if @q.blank?
      @users = collect('users', User.members.all(:conditions => {:suggested => true}, :order => :username))
      @channels = collect('channels', Channel.public.all(:conditions => {:suggested => true}, :order => :name))
    else
      @users = User.search(@q, :conditions => {:feed_owner => false}, :retry_stale => true)
      @channels = Channel.search(@q.split.join(' | '), :conditions => {:user_owned => false}, :match_mode => :boolean, :retry_stale => true)
    end
  end
  
  def suggest
    @user.update_attribute('suggested', true) if @user
    Rails.cache.write('users/default-followings', nil)
    
    @channel.update_attribute('suggested', true) if @channel
    Rails.cache.write('channels/default-subscriptions', nil)
  end
  
  def unsuggest
    @user.update_attribute('suggested', false) if @user
    Rails.cache.write('users/default-followings', nil)
    
    @channel.update_attribute('suggested', false) if @channel
    Rails.cache.write('channels/default-subscriptions', nil)
    
    render :action => "suggest"
  end
  
  
  private
  def ensure_user_can_administer
    if user_can_administer?
      yield
    else
      redirect_to '/'
    end
  end
  
  def load_suggestion
    @user = params[:user_id].blank? ? nil : User.find(params[:user_id])
    @channel = params[:channel_id].blank? ? nil : Channel.find(params[:channel_id])
    
    yield
  end
end
