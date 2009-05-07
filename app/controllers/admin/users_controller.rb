class Admin::UsersController < ApplicationController
  around_filter :load_member, :only => [:deliver_digest, :destroy]
  around_filter :ensure_user_can_administer
  layout 'page'
  
  
  def index
    searchable
    setup_pagination(:per_page => 50)
    
    if @q.blank?
      @users = collect('users', User.members.all(:order => 'created_at DESC', :offset => @offset, :limit => @per_page))
    else
      @users = User.search(@q, :page => @page, :per_page => @per_page, :conditions => {:feed_owner => false})
    end
  end
  
  def deliver_digest
    spawn do
      DigestMailer.deliver_activity(@user)
    end
    
    flash[:notice] = "A digest email has been sent to #{@user.username}."
    redirect_to :action => "index"
  end
  
  def destroy
    if @user.destroy
      flash[:notice] = 'The user was successfully destroyed.'
    else
      flash[:notice] = 'Sorry, but you will have to destroy this user manually.'
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
  
  def load_member
    if @user = User.find_by_slug(params[:id]) and !@user.feed_owner?
      yield
    else
      flash[:notice] = 'The user you are looking for does not exist.'
      redirect_to :action => "index"
    end
  end
end
