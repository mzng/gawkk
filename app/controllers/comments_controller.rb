class CommentsController < ApplicationController
  around_filter :ensure_logged_in_user, :only => [:comment, :destroy]
  around_filter :ensure_user_can_administer, :only => [:all]
  around_filter :load_comment, :only => [:destroy]
  layout 'page'
  
  
  def create
    affects_recommendation_countdown
    containerable
    
    @comment = Comment.new(params[:comment])
    
    if user_logged_in?
      @comment.user_id = logged_in_user.id
      #@comment.twitter_username = logged_in_user.twitter_account.username if (params[:tweet] and params[:tweet][:it] == '1' and logged_in_user.auto_tweet?)
      @comment.save
    else
      session[:actionable] = @comment
      
      @user = User.new
      @user.send_digest_emails = true
      render :template => 'registration/register'
    end
  end
  
  def destroy
    if user_can_edit?(@comment)
      @comment.destroy
      flash[:notice] = 'The comment was successfully destroyed.'
    end
    
    redirect_to request.env["HTTP_REFERER"]
  end
  
  
  private
  def ensure_logged_in_user
    if user_logged_in?
      yield
    else
      render :nothing => true
    end
  end
  
  def ensure_user_can_administer
    if user_can_administer?
      yield
    else
      flash[:notice] = "Go home kid. This area is under lock and key."
      redirect_to '/'
    end
  end
  
  def load_comment
    if @comment = Comment.find(params[:id])
      yield
    else
      redirect_to '/'
    end
  end
end
