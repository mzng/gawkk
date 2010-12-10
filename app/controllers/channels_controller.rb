class ChannelsController < ApplicationController
  around_filter :load_channel, :only => [:show, :subscribers]
  layout 'page'
  
  # Channel Manager
  def index
    searchable
    setup_pagination(:per_page => 42)
    setup_category_sidebar
    
    conditions  = 'user_owned = false'
    parameters  = Array.new
    
    @type = 'a'
    
    if params[:c]
      @category = Category.find(params[:c])
      redirect_to smart_channel_topic_link(@category, nil, true), :status => '301' and return
    else
      @category = nil
    end

    if params[:category]  
      @category ||= Category.find_by_slug(params[:category])
      conditions = conditions.concat(' AND (category_ids like ? OR category_ids like ? OR category_ids like ? OR category_ids like ?)')
      parameters = parameters + ["#{@category.id}", "#{@category.id} %", "% #{@category.id}", "% #{@category.id} %"]
    end

    if params[:letter]
      @letter = params[:letter]
      if @letter == '0'
        c = " AND ("
        (0..9).each do |i|
          if i > 0
            c += " OR "
          end
          c += "name LIKE ?"
          parameters = parameters + ["#{i}%"]
        end
        c += ")"
        conditions = conditions.concat(c)
      else
        conditions = conditions.concat(' AND (name LIKE ?)')
        parameters = parameters + ["#{params[:letter]}%"]
      end
    end
    order = 'name asc'
    
    @channels = Rails.cache.fetch("c_#{params[:letter]}_#{params[:category]}_#{@page}", :expires => 1.hours) do 
      Channel.all(:conditions => [conditions] + parameters, :order => order, :offset => @offset, :limit => @per_page, :include => :user)
    end

    @count = Rails.cache.fetch("c_#{params[:letter]}_#{params[:category]}_#{@page}_count", :expires => 1.hours) do
      Channel.count(:conditions => [conditions] + parameters)
    end

    @entries  = WillPaginate::Collection.new(@page, @per_page, @count)
  end
  
  
  # Streams
  def show
    set_feed_url("http://www.gawkk.com/#{@user.slug}/channel.rss")
    set_meta_description(@channel.proper_name + (@user.description.blank? ? '' : ': ' + @user.description))
    set_meta_keywords(@channel.keywords)
    set_title(@channel.proper_name)
    setup_pagination

    category = nil
    category = Category.find(@channel.category) unless @channel.category.blank?

    if category
      if category.slug =~ /television/
        pitch
        @pitch_title = "Welcome to Gawkk!"
        @pitch_key = 'channel_tv'
        set_title("Watch #{@channel.proper_name}")
        set_meta_keywords("watch #{@channel.proper_name},watch #{@channel.proper_name} online for free,watch #{@channel.proper_name} free online")
        set_meta_description "Start following #{@channel.proper_name} for free. Keep up to date with the weekly epsodes. Gawkk helps organize millions of video on the web into specific tv show channel. Watch #{@channel.proper_name}"
      elsif category.slug =~ /movies/
        pitch
        @pitch_title = "Welcome to Gawkk!"
        @pitch_key = 'channel_movie'
        set_title("Watch #{@channel.proper_name} Online For Free")
        set_meta_keywords("watch #{@channel.proper_name} Online,{title} free online,watch #{@channel.proper_name}")
        set_meta_description "Start following #{@channel.proper_name} for free online. Gawkk's proprietary technology helps organize millions of video into channel. Watch #{@channel.proper_name} Online For Free."
      else
         set_title("The #{@channel.proper_name} Channel")
      set_meta_keywords("#{@channel.proper_name},#{@channel.proper_name} channel")
      set_meta_description @user.description.blank? ? ("The {title} Channel on Gawkk. Get the latest news on #{@channel.proper_name} by following #{@channel.proper_name} channel on Gawkk") : @user.description
      end
    else
      set_title("The #{@channel.proper_name} Channel")
      set_meta_keywords("#{@channel.proper_name},#{@channel.proper_name} channel")
      set_meta_description @user.description.blank? ? ("The {title} Channel on Gawkk. Get the latest news on #{@channel.proper_name} by following #{@channel.proper_name} channel on Gawkk") : @user.description

    end

    @popular = !params[:newest]

    @related_channels = Rails.cache.fetch("r_c_#{params[:category].downcase}", :expires_in => 30.minutes) do
      Channel.in_category(@channel.category).all(:order => 'rand()', :limit => 30, :include => :user)
    end

    cache_key = "c_s_#{@user.slug}_#{@popular ? "p" : "n"}_#{@page}"

    @videos = Rails.cache.fetch(cache_key, :expires_in => 1.hour) do
      if @popular
        ids = Video.find_by_sql("SELECT videos.id FROM videos INNER JOIN saved_videos sv on videos.id = sv.video_id WHERE sv.channel_id = #{@channel.id} ORDER BY popularity_score desc LIMIT #{@per_page} OFFSET #{@offset}").collect { |x| x.id } 
      Video.find(ids, :include => [:category, {:posted_by => :channels}, {:saved_videos => {:channel => :user}}], :order => 'promoted_at DESC')
      else
        ids = @channel.videos(:select => :video_id, :order => "created_at desc", :offset => @offset, :limit => @per_page).collect { |x| x.video_id } 
      Video.find(ids, :include => [:category, {:posted_by => :channels}, {:saved_videos => {:channel => :user}}], :order => 'id DESC')
      end
    end
  end
  
  
  # Single Channel
  def subscribers
    redirect_to channel_path(@user, @channel)
  end
  
  
  # Channel Actions
  def subscribe
    # ensure_logged_in_user or do nothing
    coerce_back_to_js
    
    if @channel = Channel.find(params[:id])
      logged_in_user.subscribe_to(@channel)
    end
    
    respond_to do |format|
      format.js {}
    end
  end
  
  def unsubscribe
    # ensure_logged_in_user or do nothing
    coerce_back_to_js
    
    if @channel = Channel.find(params[:id])
      logged_in_user.unsubscribe_from(@channel)
    end
    
    respond_to do |format|
      format.js {
        render :action => "subscribe"
      }
    end
  end
  
  
  private
  def load_channel
    user_param = params[:user] || params[:channel]

    if user_param && (@user = User.find_by_slug(user_param)) and (@channel = Channel.owned_by(@user).with_slug('channel').first)
      if @user.feed_owner?
        yield
      else
        redirect_to :controller => "users", :action => "activity", :id => @user
      end
    else
      flash[:notice] = 'The channel you are looking for does not exist.'
      redirect_to :action => "index"
    end
  end
  
  def ensure_logged_in_user
    if user_logged_in?
      yield
    else
      render :nothing => true
    end
  end

  def smart_channel_topic_link(topic, character = nil, url_only = false)
    url = "http://"
    subdomain = false
    if topic
      if topic.slug == 'television-shows'
        url += "tv."
        subdomain = true
      elsif topic.slug == 'movies-previews-trailers'      
        url += "movies."
        subdomain = true
      end
    end

    url += BASE_URL

    if topic && !subdomain
      url += "/#{topic.slug}"
    end

    url += "/channels"

    if character
      url += "?letter=#{character}"
    end

   url_only ? url : link_to( (character ? character : "Channels"), url) 
  end

end
