# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  # Authorization
  def user_can_administer?
    return user_logged_in? && logged_in_user.administrator?
  end
  
  def user_can_modify?(slug)
    return user_logged_in? && ((logged_in_user.slug == slug) || logged_in_user.administrator?)
  end
  
  def logged_in_user
    if user_logged_in?
      Rails.cache.fetch("users/#{session[:user_id]}", :expires_in => 1.week) do
        User.find(session[:user_id])
      end
    else
      return nil
    end
  end
  
  def user_logged_in?
    (session[:user_id] != nil) ? true : false
  end
  
  
  def popular_icon(video)
    html = image_tag('spinner.gif', :id => "loading_for_#{video.id}", :style => 'display:none;')
    if video.popular?
      html = html + image_tag('star.png', :id => "popular_for_#{video.id}", :title => "Popular #{time_ago_in_words(video.promoted_at)} ago")
    else
      html = html + image_tag('spacer.gif', :id => "popular_for_#{video.id}")
    end
    html
  end
  
  def summarize_likes(likes)
    html = ''
    
    if likes.size > 1
      html = likes.first(likes.size - 1).collect{|v| link_to(v.user.username, user_path(:user => v.user))}.join(', ') + ' and '
    end
    
    if likes.size > 0
      html = html + link_to(likes.last.user.username, user_path(:user => likes.last.user))
    end
    
    html
  end
  
  def collapse_comments(comments)
    html = ''
    
    if comments.size > 3
      html = html + render(comments.first)
      html = html + render(:partial => '/comments/more', :locals => {:count => comments.size - 3})
      html = html + render(comments.last(2))
    else
      html = html + render(comments)
    end
    
    html
  end
end
