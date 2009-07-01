class Admin::ParametersController < ApplicationController
  around_filter :ensure_user_can_administer
  
  
  def enable
    Parameter.set(params[:id] + '_enabled', 'true')
    
    flash[:notice] = "#{params[:id]} has been enabled."
    redirect_to request.env["HTTP_REFERER"]
  end
  
  def disable
    Parameter.set(params[:id] + '_enabled', 'false')
    
    flash[:notice] = "#{params[:id]} has been disabled."
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
