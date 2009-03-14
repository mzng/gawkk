class ChangeDefaultChannelSlug < ActiveRecord::Migration
  def self.up
    Channel.update_all(['slug = ?', 'channel'])
  end

  def self.down
    
  end
end
