class RemoveTheFromChannelNames < ActiveRecord::Migration
  def self.up
    Channel.find(:all).each do |channel|
      channel.update_attribute('name', channel.name[4, channel.name.length]) if channel.name[0, 4] == 'The '
    end
  end

  def self.down
    Channel.find(:all).each do |channel|
      channel.update_attribute('name', 'The ' + channel.name) if channel.name[0, 4] != 'The '
    end
  end
end
