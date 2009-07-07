class AddDefaultUser < ActiveRecord::Migration
  def self.up
    user = User.new
    user.username = 'default'
    user.password = Util::AuthCode.generate(32)
    user.password_confirmation = user.password
    user.email = 'tom@gawkk.com'
    user.feed_owner = true
    user.save
    
    user.update_attribute('feed_owner', false)
    if channel = Channel.find(:first, :conditions => {:user_id => user.id})
      channel.update_attribute('user_owned', true)
    end
  end

  def self.down
    if user = User.find_by_slug('default')
      user.destroy
    end
  end
end
