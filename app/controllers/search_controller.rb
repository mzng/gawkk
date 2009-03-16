class SearchController < ApplicationController
  around_filter :ensure_query, :only => [:index, :channels, :members, :videos]
  skip_before_filter :verify_authenticity_token, :only => [:index, :channels, :members, :videos]
  layout 'page'
  
  
  def index
    parse_page
    
    @channels = Channel.search(@q.split.join(' | '), :page => @page, :per_page => 7, :conditions => {:user_owned => false}, :match_mode => :boolean)
    @users = User.search(@q, :page => @page, :per_page => 7, :conditions => {:feed_owner => false})
    @videos = Video.search(@q, :order => :posted_at, :sort_mode => :desc, :page => @page, :per_page => 5, :conditions => {:category_id => Category.allowed_on_front_page})
  end
  
  def channels
    setup_pagination(:per_page => 42)
    
    @channels = Channel.search(@q.split.join(' | '), :page => @page, :per_page => @per_page, :conditions => {:user_owned => false}, :match_mode => :boolean)
  end
  
  def members
    setup_pagination(:per_page => 42)
    
    @users = User.search(@q, :page => @page, :per_page => @per_page, :conditions => {:feed_owner => false})
  end
  
  def videos
    setup_pagination(:per_page => 25)
    
    @videos = Video.search(@q, :order => :posted_at, :sort_mode => :desc, :page => @page, :per_page => @per_page, :conditions => {:category_id => Category.allowed_on_front_page})
  end
  
  private
  def ensure_query
    default_queries = ['Search...', 'Search Channels...', 'Search Members...', 'Search Videos...']
    @q = params[:q]
    
    if @q and !default_queries.include?(@q)
      yield
    else
      flash[:notice] = 'You must enter a query.'
      redirect_to request.env["HTTP_REFERER"]
    end
  end
end
