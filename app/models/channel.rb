class Channel < ActiveRecord::Base
  belongs_to  :user
  
  has_many    :saved_videos, :dependent => :destroy
  has_many    :subscriptions, :dependent => :destroy
  
  # Deprecated. Only in place for clean destroys.
  has_many :import_requests, :dependent => :destroy
  
  named_scope :public, :select => 'id, name, subscriptions_count', :conditions => {:user_owned => false}
  named_scope :featured, :select => 'id, name, subscriptions_count', :conditions => {:user_owned => false, :featured => true}
  named_scope :suggested, :select => 'id, name, subscriptions_count', :conditions => {:user_owned => false, :suggested => true}
  named_scope :with_slug, lambda {|slug| {:conditions => ['lower(slug) = lower(?)', slug]}}
  named_scope :owned_by, lambda {|user| {:conditions => ['user_id = ?', user.id]}}
  named_scope :owned_by_many, lambda {|slugs| {:include => :user, :conditions => ['users.slug IN (?)', slugs]}}
  named_scope :subscribed_to_by, lambda {|user| {:joins => :subscriptions, :conditions => ['subscriptions.user_id = ?', user.id]}}
  named_scope :in_category, lambda {|category_id| {:conditions => ['user_owned = false AND (category_ids like ? OR category_ids like ? OR category_ids like ? OR category_ids like ?)', "#{category_id}", "#{category_id} %", "% #{category_id}", "% #{category_id} %"]}}
  
  validates_presence_of :name, :user_id
  validates_uniqueness_of [:name, :slug], :scope => :user_id, :message => "must be unique"
  
  
  define_index do
    indexes :name
    indexes :description
    indexes :keywords
    has mature
    has user_owned
  end
  
  
  def before_validation_on_create
    if User.find(self.user_id).channels.count == 0
      self.slug = 'channel'
      self.description = "Personal Channel of #{User.find(self.user_id).username}"
    else
      self.slug = Util::Slug.generate(self.name, false)
      self.description ||= ''
    end
    
    return true
  end
  
  def validate_on_create
    errors.add(:name, "can't be longer than 40 characters") unless self.name.length < 41 or self.user.feed_owner?
    
    return true
  end
  
  def before_create
    self.category_ids = '' if self.category_ids.blank?
    self.keywords     = '' if self.keywords.blank?
    
    return true
  end
  
  def before_save
    Rails.cache.delete(self.cache_key)
    
    return true
  end
  
  def after_save
    Rails.cache.write(self.cache_key, Channel.find(self.id, :include => :user), :expires_in => 1.week)
    
    return true
  end
  
  
  def to_param
    self.slug
  end
  
  def category
    self.category_ids.blank? ? '' : self.category_ids.split.first
  end
  
  def proper_name
    if self.name.downcase[/^the /]
      return self.name
    else
      return 'The ' + self.name
    end
  end
  
  
  def categorize!
    category_ids = Array.new
    Feed.find(:all, :conditions => ['owned_by_id = ?', self.user_id]).each do |feed|
      category_ids << feed.category_id if !feed.category_id.blank?
    end
    self.update_attribute('category_ids', category_ids.join(' '))
  end
  
  
  # Streams
  def videos(*args)
    # Speed and clean this up with the caching system
    options = args.extract_options!
    SavedVideo.in_channel(self).all(options)
  end
  
  
  # Utility Methods
  def self.default_subscriptions
    Rails.cache.fetch('channels/default-subscriptions', :expires_in => 1.week) do
      Channel.public.all(:conditions => {:suggested => true})
    end
  end
end
