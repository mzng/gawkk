class NewsItem < ActiveRecord::Base
  belongs_to :news_item_type
  belongs_to :user
  belongs_to :actionable, :polymorphic => true
  belongs_to :reportable, :polymorphic => true
  
  has_many :activity_messages
  
  named_scope :recent, :select => '*, max(news_items.created_at) AS max_created_at', :order => 'max_created_at DESC'
  named_scope :grouped_by_user, :group => 'user_id'
  named_scope :by_user, lambda {|user| {:conditions => ['user_id = ?', user.id]}}
  named_scope :by_users, lambda {|user_ids| {:conditions => ['user_id IN (?)', user_ids]}}
  
  attr_accessor :latest_related_id
  attr_accessor :latest_related
  
  
  def before_create
    self.message = '' if self.message.nil?
  end
  
  def after_create
    # 1. Generate ActivityMessage for self.user
    self.generate_message_for_user!
    
    # 2. Queue up a Job to generate ActivityMessages for all followers of self.user
    Job.enqueue(:processable => self)
    
    return true
  end
  
  def before_destroy
    ActivityMessage.delete_all(:news_item_id => self.id)
    
    return true
  end
  
  
  def generate_message_for_user!(user = nil)
    user = self.user if user.nil?
    
    if self.reportable_type == 'Video'
      ActivityMessage.update_all 'hidden = true', ['user_id = ? AND hidden = false AND reportable_type = ? AND reportable_id = ?', user.id, 'Video', self.reportable_id]
    end
  
    ActivityMessage.create :user_id => user.id, :news_item_id => self.id, :reportable_type => self.reportable_type, :reportable_id => self.reportable_id
  end
  
  def generate_messages_for_followers!
    follower_ids = Rails.cache.fetch("users/#{self.user_id}/followers", :expires_in => 1.week) do
      User.followers_of(self.user).all.collect{|follower| follower.id}
    end
    
    follower_ids.each do |follower_id|
      if self.reportable_type == 'Video'
        ActivityMessage.update_all 'hidden = true', ['user_id = ? AND hidden = false AND reportable_type = ? AND reportable_id = ?', follower_id, 'Video', self.reportable_id]
      end
      
      ActivityMessage.create :user_id => follower_id, :news_item_id => self.id, :reportable_type => self.reportable_type, :reportable_id => self.reportable_id
    end
  rescue Exception => e
    raise e
  end
  
  
  def self.report(*args)
    options = args.extract_options!
    
    if options[:type] and type = NewsItemType.cached_by_name(options[:type])
      options.merge!(:news_item_type_id => type.id)
      options.delete(:type)
      
      if options[:actionable]
        options.merge!({:actionable_type => options[:actionable].class.name, :actionable_id => options[:actionable].id})
        options.delete(:actionable)
      end
      
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
  
  def self.ungrouped_activity(user_ids, options = {})
    # Speed and clean this method up with the caching system
    activity_types = NewsItemType.find(:all, :conditions => ['kind = ?', 'about a user']).collect{|type| type.id}
    
    find(:all, :select => '*, id AS max_id', :conditions => ['news_item_type_id IN (?) AND user_id IN (?) AND hidden = false', activity_types, user_ids], :order => 'id DESC', :offset => options[:offset], :limit => options[:limit])
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
