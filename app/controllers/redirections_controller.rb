class RedirectionsController < ApplicationController
  def all_newest
    redirect_to "http://#{BASE_URL}/topics", :status => 301
  end

  def all_popular
    redirect_to "http://#{BASE_URL}/topics", :status => 301
  end

  def category_newest
    cat = Category.find_by_slug(params[:category])
    redirect_to("http://#{BASE_URL}/", :status => 301) and return if cat.nil?

    redirect_to Util::Routes.category_url(cat, true), :status => 301
  end

  def category_popular
  
    cat = Category.find_by_slug(params[:category])
 
    redirect_to("http://#{BASE_URL}/", :status => 301) and return if cat.nil?

    redirect_to Util::Routes.category_url(cat), :status => 301
  end


  def friends
    redirect_to("http://#{BASE_URL}/", :status => 301)
  end

  def all_newest_tagged
    redirect_to "http://#{BASE_URL}/topics", :status => 301
  end

  def all_popular_tagged
    redirect_to "http://#{BASE_URL}/topics", :status => 301
  end

  def category_newest_tagged
    cat = Category.find_by_slug(params[:category])
    redirect_to("http://#{BASE_URL}/", :status => 301) and return if cat.nil?

    redirect_to smart_category_link(cat, false, true), :status => 301
  end

  def category_popular_tagged
    cat = Category.find_by_slug(params[:category])
    redirect_to("http://#{BASE_URL}/", :status => 301) and return if cat.nil?

    redirect_to smart_category_link(cat, true, true), :status => 301
  end

  def user
    redirect_to("http://#{BASE_URL}/", :status => 302)    
  end

  def all_newest_rss
    redirect_to "http://#{BASE_URL}/topics", :status => 301
  end

  def all_popular_rss
    redirect_to "http://#{BASE_URL}/topics", :status => 301
  end

  def submit
    redirect_to("http://#{BASE_URL}/", :status => 301)
  end

  def activity
    redirect_to("http://#{BASE_URL}/", :status => 301)
  end

  def comments
    redirect_to("http://#{BASE_URL}/", :status => 301)
  end

  def follow
    redirect_to("http://#{BASE_URL}/", :status => 301)
  end

  def unfollow
    redirect_to("http://#{BASE_URL}/", :status => 301)
  end

  def follows
    redirect_to("http://#{BASE_URL}/", :status => 301)
  end

  def followers
    redirect_to("http://#{BASE_URL}/", :status => 301)
  end

  def channel
    user_param = params[:id]
    if user_param
      user = User.find_by_slug(user_param)
      if user && user.feed_owner
        channel = Channel.owned_by(user).with_slug('channel').first
        redirect_to Util::Routes.channel_url(channel, user), :status => 301 and return
      end
    end

    redirect_to Util::Routes.root_url, :status => 302 
  end

  def friends
    redirect_to("http://#{BASE_URL}/", :status => 301)
  end

  def subscriptions
    redirect_to("http://#{BASE_URL}/", :status => 301)
  end

  def tags
    redirect_to("http://#{BASE_URL}/", :status => 301)
  end

  def tags_rss
    redirect_to("http://#{BASE_URL}/", :status => 301)
  end

  def tags_q
    redirect_to("http://#{BASE_URL}/", :status => 301)
  end

  def tags_q_rss
    redirect_to("http://#{BASE_URL}/", :status => 301)
  end

  private
  def smart_category_link(category, popular = nil, url_only = false)
    url = "http://"
    subdomain = false
    if category.slug == 'television-shows'
      url += "tv."
      subdomain = true
    elsif category.slug == 'movies-previews-trailers'      
      url += "movies."
      subdomain = true
    end

    url += BASE_URL

    if subdomain
      
    else
      url += "/topics/#{category.slug}"
    end
   
    url_only ? url : link_to(category.name, url)
  end
end
