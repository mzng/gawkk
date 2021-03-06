class Admin::LikesController < ApplicationController
  around_filter :ensure_user_can_administer
  around_filter :load_comment, :only => [:edit, :update, :destroy]
  layout 'page'
  
  
  def index
    setup_pagination(:per_page => 50)
    
    @likes = Like.all(:order => 'created_at DESC', :offset => @offset, :limit => @per_page)
  end
  
  
  private
  def ensure_user_can_administer
    if user_can_administer?
      yield
    else
      redirect_to '/'
    end
  end
end
