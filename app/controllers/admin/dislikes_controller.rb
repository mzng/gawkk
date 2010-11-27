class Admin::DislikesController < ApplicationController
  around_filter :ensure_user_can_administer

  def index
    setup_pagination(:per_page => 50)

    @dislikes = Video.find(:all, :conditions => "dislikes_count >= 30", :order => "dislikes_count desc", 
                           :offset => @offset, :limit => @per_page)
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
