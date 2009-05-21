class TwitterController < ApplicationController
  around_filter :ensure_logged_in_user, :only => [:request_credentials]
  skip_before_filter :verify_authenticity_token, :only => [:request_credentials, :connect]
  layout 'page'
  
  
  def oauth_request
    @request_token = Util::Twitter.consumer.get_request_token
    session[:request_token] = @request_token.token
    session[:request_token_secret] = @request_token.secret
    session[:oauth_credentials] = nil
    
    redirect_to @request_token.authorize_url
  end
  
  def oauth_callback
    if session[:request_token] and session[:request_token_secret] and (params[:oauth_token].blank? or session[:request_token] == params[:oauth_token])
      @request_token = OAuth::RequestToken.new(Util::Twitter.consumer, session[:request_token], session[:request_token_secret])
      @access_token = @request_token.get_access_token
      
      session[:request_token] = nil
      session[:request_token_secret] = nil
      
      begin
        response = Util::Twitter.request(:get, '/account/verify_credentials.json', @access_token.token, @access_token.secret)
        
        if response['id']
          if twitter_account = TwitterAccount.find(:first, :conditions => {:twitter_user_id => response['id'].to_s})
            if twitter_account.access_token.blank?
              twitter_account.authenticated = false
              twitter_account.tweet_likes   = false
            end
            
            twitter_account.username      = response['screen_name']
            twitter_account.access_token  = @access_token.token
            twitter_account.access_secret = @access_token.secret
            twitter_account.save
            
            @user = twitter_account.user
            
            # Update the user's last login time
            @user.cookie_hash = bake_cookie_for(@user)
            @user.last_login_at = Time.new
            @user.save

            # Store the logged in user's id in the session
            session[:user_id] = @user.id
            
            redirect_to '/'
          else
            oauth = Hash.new
            oauth[:access_token]  = @access_token.token
            oauth[:access_secret] = @access_token.secret
            oauth[:twitter_id]          = response['id']
            oauth[:twitter_screen_name] = response['screen_name']
            oauth[:twitter_image_url]   = response['profile_image_url']
            oauth[:twitter_name]        = response['name']
            oauth[:twitter_description] = response['description']
            oauth[:twitter_website_url] = response['url']
            
            session[:oauth_credentials] = oauth

            redirect_to :controller => 'registration', :action => 'setup_suggestions'
          end
        else
          flash[:notice] = 'The authentication failed. Please try again!'
          redirect_to '/'
        end
        
      rescue Util::Twitter::Unauthorized, Util::Twitter::HTTPError
        flash[:notice] = 'The authentication failed. Please try again!'
        redirect_to '/'
      end
    else
      flash[:notice] = 'The authentication failed. Please try again!'
      redirect_to '/'
    end
  end
  
  def connect
    if request.get?
      @oauth = session[:oauth_credentials]
      
      @user = User.new
      @user.send_digest_emails = true
      
      if !@oauth[:twitter_screen_name].blank?
        @user.username = @oauth[:twitter_screen_name]
        
        attempt = 0
        while !User.valid_username?(@user.username) and attempt < 3 do
          if @user.username.length < 15
            @user.username = @user.username + rand(10).to_s
          else
            @user.username = @user.username[0, 14] + rand(10).to_s
          end
          
          attempt = attempt + 1
        end
      end
    else
      @oauth = session[:oauth_credentials]
      
      @user = User.new(params[:user])
      @user.name = @oauth[:twitter_name]
      @user.description = @oauth[:twitter_description]
      @user.twitter_username = @oauth[:twitter_screen_name]
      @user.website_url   = @oauth[:website_url]
      @user.ad_campaign   = session[:ref]
      @user.administrator = false
      @user.feed_owner    = false
      @user.twitter_oauth = true
      
      @user.password = Util::AuthCode.generate(32)
      @user.password_confirmation = @user.password
      
      if @user.save
        # Remember this user
        @user.cookie_hash = bake_cookie_for(@user)
        @user.save
        
        # Fetch and set Twitter avatar
        Util::Avatar.fetch_from_twitter(@user)
        Util::Avatar.use_service_avatar(@user, 'twitter')
        
        # Store Twitter account information
        twitter_account = TwitterAccount.new
        twitter_account.user_id = @user.id
        twitter_account.twitter_user_id = @oauth[:twitter_id]
        twitter_account.username = @oauth[:twitter_screen_name]
        twitter_account.access_token  = @oauth[:access_token]
        twitter_account.access_secret = @oauth[:access_secret]
        twitter_account.authenticated = false
        twitter_account.tweet_likes   = false
        
        if twitter_account.save
          session[:oauth_credentials] = nil
        end
        
        session[:user_id] = @user.id
      end
      
      redirect_to :controller => "registration", :action => "setup_suggestions"
    end
  end
  
  
  def please_register
    flash[:notice] = 'Register or Login so that you can start tweeting your activity.'
    redirect_to :controller => "registration", :action => "register"
  end
  
  def request_credentials
    @twitter_account = logged_in_user.twitter_account ? logged_in_user.twitter_account : TwitterAccount.new
  end
  
  def update_credentials
    @twitter_account = logged_in_user.twitter_account ? logged_in_user.twitter_account : TwitterAccount.new
    @twitter_account.user_id  = logged_in_user.id
    
    if @twitter_account.access_token.blank?
      @twitter_account.username = params[:twitter_account][:username]
      @twitter_account.password = params[:twitter_account][:password]
    else
      @twitter_account.authenticated = (params[:twitter_account][:authenticated] == '1' ? true : false)
    end
    
    @twitter_account.tweet_likes = (params[:twitter_account][:tweet_likes] == '1' ? true : false)
    
    @twitter_account.save
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
