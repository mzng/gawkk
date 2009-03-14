class GenerateWelcomeNewsItems < ActiveRecord::Migration
  def self.up
    User.find(:all, :conditions => ['feed_owner = false']).each do |user|
      news_item = NewsItem.report('welcome', user, nil)
      registered_at = user.created_at
      registered_at = Time.parse('09-01-2007') if registered_at.nil?
      news_item.update_attribute('created_at', registered_at)
    end
  end

  def self.down
    
  end
end
