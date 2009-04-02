class Admin::ImportController < ApplicationController
  around_filter :ensure_user_can_administer
  layout 'page'
  
  
  def shutdown
    Parameter.set('feed_importer_status', 'false')
    
    flash[:notice] = 'All feed importers have been instructed to shutdown.'
    redirect_to request.env["HTTP_REFERER"]
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
