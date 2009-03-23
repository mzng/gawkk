class CommentsController < ApplicationController
  around_filter :ensure_logged_in_user, :only => [:like, :comment]
  
  def create
    @comment = Comment.new(params[:comment])
    @comment.user_id = logged_in_user.id
    @comment.save
    
    spawn do
      if params[:tweet][:it] == '1' and logged_in_user.auto_tweet?
        Tweet.report('make_a_comment', logged_in_user, @comment)
      end
    end
    
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
