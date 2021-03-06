# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def request_for_facebook?
    (request.subdomains.first == 'web1' or request.subdomains.first == 'facebook') ? true : false
  end
  
  def outstanding_invitation
    if !session[:invitation_id].blank?
      Rails.cache.fetch("invitations/#{session[:invitation_id]}", :expires_in => 6.hours) do
        Invitation.find(session[:invitation_id])
      end
    elsif !session[:host_id].blank?
      Invitation.new(:host_id => session[:host_id])
    else
      return nil
    end
  end
  
  def subscribed_channels
    if user_logged_in?
      @subscribed_channels = Rails.cache.fetch("users/#{logged_in_user.id.to_s}/subscribed_channels", :expires_in => 2.weeks) do
        collect('channels', logged_in_user.subscribed_channels(:order => 'channels.name ASC'))
      end
    else
      @subscribed_channels = Rails.cache.fetch("users/default/subscribed_channels", :expires_in => 2.weeks) do
        collect('channels', User.new.subscribed_channels(:order => 'channels.name ASC'))
      end
    end
  end
  
  # Authorization
  def user_can_administer?
    return user_logged_in? && logged_in_user.administrator?
  end
  
  def user_can_modify?(slug)
    return user_logged_in? && ((logged_in_user.slug == slug) || logged_in_user.administrator?)
  end
  
  def logged_in_user
    return @currently_logged_in_user if defined?(@currently_logged_in_user)
    if user_logged_in?
      @currently_logged_in_user = Rails.cache.fetch("users/#{session[:user_id]}", :expires_in => 1.week) do
        User.find(session[:user_id])
      end
    else
      @currently_logged_in_user = nil
    end
    return @currently_logged_in_user
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
    elsif object.class == NewsItem
      if user_logged_in? and (user_can_administer? or object.user_id == logged_in_user.id)
        return true
      end
    end
    
    return false
  end
  
  
  def referrer_is?(ref)
    return (!session[:ref].blank? and session[:ref] == ref) ? true : false
  end
  
  
  def auto_link_usernames(body)
    html = h(body)
    
    html = Util::Scrub.autolink_usernames(html)
    
    html
  end
  
  def popular_icon(video, container_id)
    html = image_tag('spinner.gif', :id => "loading_for_#{video.id}#{container_id}", :style => 'display:none;')
    if video.popular?
      html = html + image_tag('star.png', :id => "popular_for_#{video.id}#{container_id}", :title => "Popular #{time_ago_in_words(video.promoted_at)} ago")
    else
      html = html + image_tag('spacer.gif', :id => "popular_for_#{video.id}#{container_id}")
    end
    html
  end
  
  def summarize_likes(likes, preferred_username = false)
    html = ''
    
    if likes.size > 1
      html = likes.first(likes.size - 1).collect{|v| link_to((preferred_username ? v.user.preferred_username : v.user.username), user_path(:id => v.user))}.join(', ') + ' and '
    end
    
    if likes.size > 0
      html = html + link_to((preferred_username ? likes.last.user.preferred_username : likes.last.user.username), user_path(:id => likes.last.user))
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
  
  def first_letter(contact_name)
    letter = contact_name.first(1).upcase
    letter = '#' if !('A'..'Z').to_a.include?(letter)
    
    return letter
  end
end
