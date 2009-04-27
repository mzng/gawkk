class TwitterController < ApplicationController
  around_filter :ensure_logged_in_user, :only => [:request_credentials]
  skip_before_filter :verify_authenticity_token, :only => [:request_credentials]
  layout 'page'
  
  
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
