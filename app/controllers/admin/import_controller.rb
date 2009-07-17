class Admin::ImportController < ApplicationController
  around_filter :ensure_user_can_administer
  layout 'page'
  
  
  def restart
    Parameter.set('feed_importer_status', 'true')
    
    flash[:notice] = 'All feed importers have been instructed to restart.'
    redirect_to request.env["HTTP_REFERER"]
  end
  
  def shutdown
    Parameter.set('feed_importer_status', 'false')
    
    flash[:notice] = 'All feed importers have been instructed to shutdown.'
    redirect_to request.env["HTTP_REFERER"]
  end
  
  def fix_thumbnails
    system "/usr/local/bin/rake thumbnail:fixer RAILS_ENV=#{Rails.env} --trace >> #{Rails.root}/log/rake.thumbnail.fixer.log &"
    
    flash[:notice] = 'The thumbnail:fixer rake task has been started in the background.'
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
