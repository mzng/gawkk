class Admin::UsersController < ApplicationController
  around_filter :ensure_user_can_administer
  layout 'page'
  
  
  def index
    setup_pagination(:per_page => 50)
    
    @users = collect('users', User.members.all(:order => 'created_at DESC', :offset => @offset, :limit => @per_page))
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
