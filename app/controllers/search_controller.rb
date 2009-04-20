class SearchController < ApplicationController
  around_filter :ensure_query, :only => [:index, :channels, :members, :videos, :youtube]
  skip_before_filter :verify_authenticity_token, :only => [:index, :channels, :members, :videos, :youtube]
  layout 'page'
  
  
  def index
    parse_page
    
    @channels = Channel.search(@q.split.join(' | '), :page => @page, :per_page => 7, :conditions => {:user_owned => false}, :match_mode => :boolean)
    @users = User.search(@q, :page => @page, :per_page => 7, :conditions => {:feed_owner => false})
    @videos = Video.search(@q, :order => :posted_at, :sort_mode => :desc, :page => @page, :per_page => 5, :conditions => {:category_id => Category.allowed_on_front_page_ids})
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
    
    @videos = Video.search(@q, :order => :posted_at, :sort_mode => :desc, :page => @page, :per_page => @per_page, :conditions => {:category_id => Category.allowed_on_front_page_ids})
  end
  
  def youtube
    respond_to do |format|
      format.html {
        begin
          setup_pagination(:per_page => 25)

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
    default_queries = ['Search...', 'Search Channels...', 'Search Members...', 'Search Videos...']
    
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
