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
  
  def user_can_edit?(object)
    if object.class == Video
      if user_logged_in? and (user_can_administer? or object.posted_by_id == logged_in_user.id)
        return true
      end
    elsif object.class == User
      if user_logged_in? and (user_can_administer? or object.id == logged_in_user.id)
        return true
      end
    elsif object.class == Comment
      if user_logged_in? and (user_can_administer? or object.user_id == logged_in_user.id)
        return true
      end
    end
    
    return false
  end
  
  
  def referrer_is?(ref)
    return (!session[:ref].blank? and session[:ref] == ref) ? true : false
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
      html = likes.first(likes.size - 1).collect{|v| link_to(v.user.username, user_path(:id => v.user))}.join(', ') + ' and '
    end
    
    if likes.size > 0
      html = html + link_to(likes.last.user.username, user_path(:id => likes.last.user))
    end
    
    html
  end
  
  def summarize_likes_absolute(likes)
    html = ''
    
    if likes.size > 1
      html = likes.first(likes.size - 1).collect{|v| "<a href=\"http://gawkk.com/#{v.user.slug}\">#{v.user.username}</a>"}.join(', ') + ' and '
    end
    
    if likes.size > 0
      html = html + "<a href=\"http://gawkk.com/#{likes.last.user.slug}\">#{likes.last.user.username}</a>"
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
  
  def bold_for(action)
    css = ''
    
    if params[:action] == action
      css = 'font-weight:bold;'
    end
    
    css
  end
  
  def bold_for_option(compared_with, current)
    css = ''
    
    if compared_with == current
      css = 'font-weight:bold;'
    end
    
    css
  end
end
