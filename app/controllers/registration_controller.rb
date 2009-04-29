class RegistrationController < ApplicationController
  around_filter :load_user, :only => [:setup_services, :setup_profile]
  layout 'page'
  
  
  def username_check
    @valid = true
    
    if !params[:username].blank?
      @username = params[:username]
      
      if @username.length < 4
        @valid = false
      end
      
      if @valid and @username.length > 15
        @valid = false
      end
      
      if @valid and @username.match(/\s/)
        @valid = false
      end
      
      if @valid and @username.match(/\./)
        @valid = false
      end
      
      if @valid and !User.unique_username?(@username)
        @valid = false
      end
    else
      @username = 'username'
      @valid   = nil
    end
  end
  
  def register
    if !user_logged_in?
      if request.get?
        @user = User.new
        @user.send_digest_emails = true
      else
        if params[:user][:password_confirmation].nil?
          params[:user][:password_confirmation] = params[:user][:password]
        end
        
        @user = User.new(params[:user])
        @user.ad_campaign   = session[:ref]
        @user.administrator = false
        @user.feed_owner    = false
        
        if @user.save
          session[:user_id] = @user.id
          redirect_to :action => "setup_services"
        end
      end
    else
      redirect_to :action => "setup_services"
    end
  end
  
  def setup_services
    # load_user or redirect
    if request.put?
      @user.twitter_username    = params[:user][:twitter_username]
      @user.friendfeed_username = params[:user][:friendfeed_username]
      @user.youtube_username    = params[:user][:youtube_username]
      @user.website_url         = params[:user][:website_url]
      @user.feed_url            = params[:user][:feed_url]
      
      if @user.save
        session[:user_id] = @user.id
        redirect_to :action => "setup_profile"
      end
    end
  end
  
  def setup_profile
    # load_user or redirect
    if request.get?
      @service_avatars = Util::Avatar.collect_avatars(@user)
      @age_ranges = AgeRange.collect
    else
      if params[:avatar] and params[:avatar][:for_user] != nil and params[:avatar][:for_user].class != String
        Util::Avatar.use_file_avatar(@user, params[:avatar][:for_user])
      elsif !params[:use][:service].blank?
        Util::Avatar.use_service_avatar(@user, params[:use][:service])
      end
      
      @user.name          = params[:user][:name]
      @user.age_range_id  = params[:user][:age_range_id]
      @user.sex           = params[:user][:sex]
      @user.location      = params[:user][:location]
      @user.zip_code      = params[:user][:zip_code]
      
      if @user.save
        flash[:notice] = 'Your registration is complete!'
        redirect_to '/'
      end
    end
  end
  
  private
  def load_user
    if user_logged_in? and @user = User.find(logged_in_user.id)
      yield
    else
      flash[:notice] = 'You must be logged in to do that.'
      redirect_to :controller => "authentication", :action => "login"
    end
  end
end
