class NewsItem < ActiveRecord::Base
  belongs_to :news_item_type
  belongs_to :user
  belongs_to :reportable, :polymorphic => true
  belongs_to :comment
  
  named_scope :recent, :select => '*, max(news_items.created_at) AS max_created_at', :order => 'max_created_at DESC'
  named_scope :grouped_by_user, :group => 'user_id'
  named_scope :by_users, lambda {|user_ids| {:conditions => ['user_id IN (?)', user_ids]}}
  
  attr_accessor :latest_related_id
  attr_accessor :latest_related
  
  
  def before_create
    self.message = '' if self.message.nil?
  end
  
  
  def self.report(*args)
    options = args.extract_options!
    
    if options[:type] and type = NewsItemType.cached_by_name(options[:type])
      options.merge!(:news_item_type_id => type.id)
      options.delete(:type)
      
      if options[:reportable]
        options.merge!({:reportable_type => options[:reportable].class.name, :reportable_id => options[:reportable].id})
        options.delete(:reportable)
      end
      
      NewsItem.create(options)
    end
  end
  
  def self.grouped_activity(user_ids, options = {})
    # Speed and clean this method up with the caching system
    activity_types = NewsItemType.find(:all, :conditions => ['kind = ?', 'about a user']).collect{|type| type.id}
    
    options[:order] = 'max_id DESC'
    
    union([{:select => '*, max(id) AS max_id', 
            :conditions => ["news_item_type_id IN (?) AND reportable_type = 'Video' AND user_id IN (?) AND hidden = false", activity_types, user_ids], :group => 'reportable_id'}, 
           {:select => '*, id AS max_id', 
            :conditions => ["news_item_type_id IN (?) AND (reportable_type != 'Video' OR reportable_type IS NULL) AND user_id IN (?) AND hidden = false", activity_types, user_ids]}], 
            options)
  end
  
  
  def render(link_user = true, absolute = false, format = '')
    prefix = absolute ? 'http://www.gawkk.com' : ''
    html = self.news_item_type.template
    html = html.gsub(/\{channel\}/, "<a href=\"#{prefix}/#{self.reportable.user.slug}/#{self.reportable.slug}#{format}\">#{channel_name(self.reportable.name)}</a>") if self.reportable and self.reportable.class == Channel
    html = html.gsub(/\{channel.listing\}/, "<div style=\"height:54px;margin:5px 0px;width:105px;\"><div style=\"font-size:8pt;float:right;height:40px;line-height:9pt;padding-top:14px;text-align:center;\"><a href=\"#{prefix}/#{self.reportable.user.slug}/#{self.reportable.slug}#{format}\">View<br/>Channel</a></div><a href=\"#{prefix}/#{self.reportable.user.slug}/#{self.reportable.slug}#{format}\"><img src=\"#{prefix}/images/#{self.reportable.user.thumbnail.blank? ? 'profile-pic.jpg' : self.reportable.user.thumbnail}\" style=\"border:1px solid #E5E5E5;float:left;height:52px;width:52px;\"/></a></div>") if self.reportable and self.reportable.class == Channel
    html = html.gsub(/\{friend\}/, "<a href=\"#{prefix}/#{self.reportable.slug}/profile#{format}\">#{self.reportable.username}</a>") if self.reportable and self.reportable.class == User
    html = html.gsub(/\{friend.listing\}/, "<div style=\"height:54px;margin:5px 0px;width:95px;\"><div style=\"font-size:8pt;float:right;height:40px;line-height:9pt;padding-top:14px;text-align:center;\"><a href=\"#{prefix}/#{self.reportable.slug}/profile#{format}\">View<br/>Profile</a></div><a href=\"#{prefix}/#{self.reportable.slug}/profile#{format}\"><img src=\"#{prefix}/images/#{self.reportable.thumbnail.blank? ? 'profile-pic.jpg' : self.reportable.thumbnail}\" style=\"border:1px solid #E5E5E5;float:left;height:52px;width:52px;\"/></a></div>") if self.reportable and self.reportable.class == User
    html = html.gsub(/\{message\}/, self.message)
    if link_user
      html = html.gsub(/\{user\}/, "<a href=\"#{prefix}/#{self.user.slug}/profile#{format}\">#{self.user.username}</a>")
    else
      html = html.gsub(/\{user\}/, self.user.username)
    end
    html = html.gsub(/\{video\}/, "<a href=\"#{prefix}/#{self.reportable.slug}/discuss#{format}\">#{self.reportable.name}</a>") if self.reportable and self.reportable_type == 'Video'
    html = html.gsub(/\{video.listing\}/, "<div style=\"height:54px;margin:5px 0px;width:115px;\"><div style=\"font-size:8pt;float:right;height:40px;line-height:9pt;padding-top:14px;text-align:center;\"><a href=\"#{prefix}/#{self.reportable.slug}/discuss#{format}\">View<br/>Video</a></div><a href=\"#{prefix}/#{self.reportable.slug}/discuss#{format}\"><img src=\"#{prefix}/images/#{self.reportable.thumbnail.blank? ? 'no-image.jpg' : self.reportable.thumbnail}\" style=\"border:1px solid #E5E5E5;float:left;height:52px;width:74px;\"/></a></div>") if self.reportable and self.reportable.class == Video
    if self.reportable and self.reportable.class == Video and self.news_item_type.name == 'make_a_comment'
      html = html.gsub(/\{commentable_type\}/, "video")
      html = html.gsub(/\{commentable\}/, "<a href=\"#{prefix}/#{self.reportable.slug}/discuss#{format}\">#{self.reportable.name}</a>")
      html = html.gsub(/\{comment.body\}/, "<div style=\"margin:5px 0px;" + (self.message.blank? ? "width:115px;\"><div style=\"font-size:8pt;float:right;height:40px;line-height:9pt;padding-top:14px;text-align:center;\"><a href=\"#{prefix}/#{self.reportable.slug}/discuss#{format}\">View<br/>Video</a></div>" : "\">") + "<a href=\"#{prefix}/#{self.reportable.slug}/discuss#{format}\"><img src=\"#{prefix}/images/#{self.reportable.thumbnail.blank? ? 'no-image.jpg' : self.reportable.thumbnail}\" style=\"border:1px solid #E5E5E5;float:left;height:52px;margin-right:5px;width:74px;\"/></a>#{self.message.blank? ? '' : "<em>\"" + self.message + "\"</em>"}</div>")
    elsif self.reportable and self.reportable.class == User and self.news_item_type.name = 'make_a_comment'
      html = html.gsub(/\{commentable_type\}/, "member")
      html = html.gsub(/\{commentable\}/, "<a href=\"#{prefix}/#{self.reportable.slug}/profile#{format}\">#{self.reportable.username}</a>")
      html = html.gsub(/\{comment.body\}/, "<div style=\"margin:5px 0px;" + (self.message.blank? ? "width:115px;\"><div style=\"font-size:8pt;float:right;height:40px;line-height:9pt;padding-top:14px;text-align:center;\"><a href=\"#{prefix}/#{self.reportable.slug}/profile#{format}\">View<br/>Profile</a></div>" : "\">") + "<a href=\"#{prefix}/#{self.reportable.slug}/profile#{format}\"><img src=\"#{prefix}/images/#{self.reportable.thumbnail.blank? ? 'profile-pic.jpg' : self.reportable.thumbnail}\" style=\"border:1px solid #E5E5E5;float:left;height:52px;margin-right:5px;width:52px;\"/></a>#{self.message.blank? ? '' : "<em>\"" + self.message + "\"</em>"}</div>")
    end
    html = html.gsub(/\{format\}/, format)
    
    return html
  end
  
  def render_simple
    html = self.news_item_type.simple_template
    html = html.gsub(/\{user\}/, "<a href=\"/#{self.user.slug}\">#{self.user.username}</a>")
    
    if self.message.blank?
      html = html.gsub(/\{comment\}/, " commented on this {commentable_type}")
      html = html.gsub(/\{commentable_type\}/, self.reportable_type.downcase)
    else
      html = html.gsub(/\{comment\}/, ": {comment.body}")
      html = html.gsub(/\{comment.body\}/, self.message)
    end
    
    html = Util::Scrub.autolink_usernames(html)
    
    return html
  end
  
  private
  def channel_name(name)
    if name.downcase[/^the /]
      return name
    else
      return 'The ' + name
    end
  end
end
