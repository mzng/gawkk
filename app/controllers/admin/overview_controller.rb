class Admin::OverviewController < ApplicationController
  around_filter :ensure_user_can_administer
  layout 'page'
  
  
  def index
    
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
