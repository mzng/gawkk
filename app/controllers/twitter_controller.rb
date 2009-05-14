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
          # if this user already exists, sign them in
          # else sign them up
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
          # end
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
      if !@oauth[:twitter_screen_name].blank?
        @user.username = @oauth[:twitter_screen_name]
        @user.send_digest_emails = true
      
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
    @twitter_account.username = params[:twitter_account][:username]
    @twitter_account.password = params[:twitter_account][:password]
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
