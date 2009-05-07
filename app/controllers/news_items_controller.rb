class NewsItemsController < ApplicationController
  around_filter :ensure_logged_in_user, :only => [:destroy]
  around_filter :load_news_item, :only => [:destroy]
  
  
  def destroy
    if user_can_edit?(@news_item)
      @news_item.update_attribute('hidden', true)
      flash[:notice] = 'The news item was successfully destroyed.'
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
  
  def load_news_item
    if @news_item = NewsItem.find(params[:id])
      yield
    else
      redirect_to '/'
    end
  end
end
