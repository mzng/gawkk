class Admin::CommentsController < ApplicationController
  around_filter :ensure_user_can_administer
  around_filter :load_comment, :only => [:edit, :update, :destroy]
  layout 'page'
  
  
  def index
    setup_pagination(:per_page => 50)
    
    @comments = Comment.all(:order => 'created_at DESC', :offset => @offset, :limit => @per_page)
  end
  
  def edit
    
  end
  
  def update
    @comment.body = params[:comment][:body]
    
    if @comment.save
      flash[:notice] = 'The comment was successfully updated.'
      redirect_to :action => "index"
    end
  end
  
  def destroy
    @comment.destroy
    
    flash[:notice] = 'The comment was successfully destroyed.'
    redirect_to :action => "index"
  end
  
  
  private
  def ensure_user_can_administer
    if user_can_administer?
      yield
    else
      redirect_to '/'
    end
  end
  
  def load_comment
    if @comment = Comment.find(params[:id])
      yield
    else
      redirect_to :action => "index"
    end
  end
end
