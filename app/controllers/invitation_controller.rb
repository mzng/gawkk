class InvitationController < ApplicationController
  around_filter :ensure_logged_in_user
  layout 'page'
  
  
  def new
    containerable
    
    @friends    = logged_in_user.friends(:order => 'lower(username) ASC')
    @contacts   = logged_in_user.contacts(:order => 'lower(email) ASC')
    
    respond_to do |format|
      format.js {}
    end
  end
  
  def add_email
    containerable
    
    @video_id = params[:video_id]
    @email = nil
    
    if @video_id and params[:email_to_add] and params[:email_to_add] != 'Enter an Email...'
      if params[:email_to_add][/^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/]
        @email = params[:email_to_add]
      end
    end
    
    respond_to do |format|
      format.js {}
    end
  end
  
  def select_friend
    containerable
    
    if params[:friend] and params[:friend][/^user_/]
      @video_id = params[:friend].split('_for_')[1].split('_')[0].to_i
      @friend   = User.find(params[:friend].split('_for_')[0].split('_')[1].to_i)
      @contact  = nil
    elsif params[:friend] and params[:friend][/^contact_/]
      @video_id = params[:friend].split('_for_')[1].split('_')[0].to_i
      @contact  = Contact.find(params[:friend].split('_for_')[0].split('_')[1].to_i)
      @friend   = nil
    end
    
    respond_to do |format|
      format.js {}
    end
  end
  
  def unselect
    containerable
    
    @video_id = params[:video_id]
    @friend   = params[:friend_id].nil? ? nil : User.find(params[:friend_id])
    @contact  = params[:contact_id].nil? ? nil : Contact.find(params[:contact_id])
    @email    = params[:email].nil? ? nil : params[:email]
    
    respond_to do |format|
      format.js {}
    end
  end
  
  def close
    containerable
    
    @video_id = params[:video_id]
    
    respond_to do |format|
      format.js {}
    end
  end
  
  
  private
  def ensure_logged_in_user
    if user_logged_in?
      yield
    else
      render :nothing => true
    end
  end
end
