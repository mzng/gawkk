class TwitterController < ApplicationController
  around_filter :ensure_logged_in_user, :only => [:request_credentials]
  layout 'page'
  
  
  def request_credentials
    @twitter_account = logged_in_user.twitter_account ? logged_in_user.twitter_account : TwitterAccount.new
    
    respond_to do |format|
      format.js {}
    end
  end
  
  def update_credentials
    @twitter_account = logged_in_user.twitter_account ? logged_in_user.twitter_account : TwitterAccount.new
    @twitter_account.user_id  = logged_in_user.id
    @twitter_account.username = params[:twitter_account][:username]
    @twitter_account.password = params[:twitter_account][:password]
    
    @twitter_account.save
    
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
