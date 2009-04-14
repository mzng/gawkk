class SettingsController < ApplicationController
  around_filter :ensure_logged_in_user, :only => [:profile, :services, :avatar, :email, :password]
  layout 'page'
  
  
  def index
    redirect_to :action => "profile", :id => params[:id]
  end
  
  def profile
    # ensure_logged_in_user or redirect
    
    if request.put?
      @user.name          = params[:user][:name]
      @user.age_range_id  = params[:user][:age_range_id]
      @user.sex           = params[:user][:sex]
      @user.location      = params[:user][:location]
      @user.zip_code      = params[:user][:zip_code]
      @user.description   = params[:user][:description]
      
      if @user.save
        flash[:notice] = 'Your profile has been updated successfully.'
      end
    end
    
    @age_ranges = AgeRange.collect
  end
  
  def services
    # ensure_logged_in_user or redirect
    
    if request.put?
      @user.twitter_username    = params[:user][:twitter_username]
      @user.friendfeed_username = params[:user][:friendfeed_username]
      @user.youtube_username    = params[:user][:youtube_username]
      @user.website_url         = params[:user][:website_url]
      @user.feed_url            = params[:user][:feed_url]
      
      if @user.save
        flash[:notice] = 'Your profile has been updated successfully.'
      end
    end
    
    @age_ranges = AgeRange.collect
    
    render :action => "profile"
  end
  
  def avatar
    # ensure_logged_in_user or redirect
    
    if request.put?
      if params[:avatar] and params[:avatar][:for_user] != nil and params[:avatar][:for_user].class != String
        Util::Avatar.use_file_avatar(@user, params[:avatar][:for_user])
      elsif !params[:use][:service].blank?
        Util::Avatar.use_service_avatar(@user, params[:use][:service])
      end
    end
    
    @service_avatars = Util::Avatar.collect_avatars(@user)
  end
  
  def email
    # ensure_logged_in_user or redirect
    
    if request.put?
      if !User.new(:email => @user.email, :password => params[:user][:password]).try_to_login.nil?
        if !params[:user][:email].blank? and params[:user][:email][/^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/] and User.unique_email?(params[:user][:email])
          @user.email = params[:user][:email]
          
          if @user.save
            flash[:notice] = 'Your email address has been updated successfully.'
          end
          
        elsif params[:user][:email].blank?
          flash[:notice] = 'Sorry, the email address can not be blank.'
        elsif !params[:user][:email][/^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/]
          flash[:notice] = 'Sorry, the email address you entered is invalid.'
        else
          flash[:notice] = 'Sorry, the email address you entered is already being used.'
        end
      else
        flash[:notice] = 'The password you entered was incorrect.'
      end
    end
  end
  
  def password
    # ensure_logged_in_user or redirect
    
    if request.put?
      if !User.new(:email => @user.email, :password => params[:old][:password]).try_to_login.nil?
        if !params[:user][:password].blank?
          @user.password = params[:user][:password]
          @user.password_confirmation = params[:user][:password_confirmation]

          if @user.save
            flash[:notice] = 'Your password has been changed successfully.'
            
            @user.password = nil
            @user.password_confirmation = nil
          end
        end
      else
        flash[:notice] = 'The password you entered was incorrect.'
      end
    end
  end
  
  
  private
  def ensure_logged_in_user
    if user_logged_in? and @user = ((user_can_administer? and !params[:id].blank? and User.find_by_slug(params[:id])) or User.find(logged_in_user.id))
      params[:id] = nil if @user.id == logged_in_user.id
      yield
    else
      flash[:notice] = 'You must be logged in to the do that.'
      redirect_to :controller => "authentication", :aciton => "login"
    end
  end
end
