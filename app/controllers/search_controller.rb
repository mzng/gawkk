class SearchController < ApplicationController
  around_filter :ensure_query, :only => [:index, :channels, :members, :videos, :youtube]
  skip_before_filter :verify_authenticity_token, :only => [:index, :channels, :members, :videos, :youtube]
  layout 'page'
  
  
  def index
    parse_page
    setup_generic_sidebar
    setup_user_sidebar(logged_in_user) if user_logged_in?
    Search.create :query => @q unless @q.blank?
    @channels = Channel.search(@q.split.join(' | '), :page => @page, :per_page => 7, :conditions => {:user_owned => false}, :match_mode => :boolean, :retry_stale => true)
    @videos = Video.search(@q, :order => :posted_at, :sort_mode => :desc, :page => @page, :per_page => 5, :conditions => {:category_id => Category.allowed_on_front_page_ids}, :retry_stale => true)
  end
  
  def channels
    setup_pagination(:per_page => 42)
    setup_generic_sidebar
    setup_user_sidebar(logged_in_user) if user_logged_in?
    
    @channels = Channel.search(@q.split.join(' | '), :page => @page, :per_page => @per_page, :conditions => {:user_owned => false}, :match_mode => :boolean, :retry_stale => true)
  end
  
  def members
    setup_pagination(:per_page => 42)
    setup_generic_sidebar
    setup_user_sidebar(logged_in_user) if user_logged_in?
    
    @users = User.search(@q, :page => @page, :per_page => @per_page, :conditions => {:feed_owner => false}, :retry_stale => true)
  end
  
  def videos
    setup_pagination(:per_page => 25)
    setup_generic_sidebar
    setup_user_sidebar(logged_in_user) if user_logged_in?
    
    @videos = Video.search(@q, :order => :posted_at, :sort_mode => :desc, :page => @page, :per_page => @per_page, :conditions => {:category_id => Category.allowed_on_front_page_ids}, :retry_stale => true)
  end
  
  def youtube
    respond_to do |format|
      format.html {
        begin
          setup_pagination(:per_page => 25)
          setup_generic_sidebar
          setup_user_sidebar(logged_in_user) if user_logged_in?

          client = Util::YouTube.client
          @result = client.videos_by(:query => @q, :offset => (@offset == 0 ? nil : @offset), :max_results => @per_page)
        rescue
          flash[:notice] = "YouTube is broken! The internet is collaposing upon itself! <a href=\"/search/youtube?q=#{@q}\">Try again</a>."
          redirect_to :action => "index", :q => @q
        end
      }
      format.js {
        begin
          client = Util::YouTube.client
          @result = client.videos_by(:query => @q, :max_results => 5)
        rescue
          @results = nil
        end
      }
    end
  end
  
  private
  def ensure_query
    searchable
    default_queries = ['Search...', 'Search Millions of Videos...', 'Search Channels...', 'Search Members...', 'Search Videos...']
    
    if @q and !@q.blank? and !default_queries.include?(@q)
      yield
    else
      flash[:notice] = 'You must enter a query.'
      
      if request.env["HTTP_REFERER"].blank?
        redirect_to :controller => "videos", :action => "friends"
      else
        redirect_to request.env["HTTP_REFERER"]
      end
    end
  end
end
