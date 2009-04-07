class TagsController < ApplicationController
  layout 'page'
  
  
  def index
    searchable(:convert_tags => true, :titleize => true)
    
    set_feed_url("http://www.gawkk.com/tags/#{@q.downcase}.rss")
    set_title("#{@q} Videos")
    
    setup_pagination
    
    @videos = Video.search(@q, :order => :posted_at, :sort_mode => :desc, :page => @page, :per_page => @per_page, :conditions => {:category_id => Category.allowed_on_front_page_ids})
  end
end
