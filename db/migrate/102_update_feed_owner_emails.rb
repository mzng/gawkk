class UpdateFeedOwnerEmails < ActiveRecord::Migration
  def self.up
    User.find(:all, :conditions => 'feed_owner = true').each do |user|
      say user.slug
      user.update_attribute('email', 'feed-owner+' + Util::Slug.generate(user.username, false) + '@gawkk.com')
    end
  end

  def self.down
    
  end
end
