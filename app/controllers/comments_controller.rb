class CommentsController < ApplicationController
  around_filter :ensure_logged_in_user, :only => [:like, :comment]
  
  def create
    @comment = Comment.new(params[:comment])
    @comment.user_id = logged_in_user.id
    @comment.save
    
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
