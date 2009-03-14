class AddSubscriptionsCountToChannels < ActiveRecord::Migration
  def self.up
    add_column :channels, :subscriptions_count, :integer, :default => 0, :null => false
    Channel.reset_column_information
    
    Channel.find(:all).each do |channel|
      channel.recalculate_counts
    end
  end

  def self.down
    remove_column :channels, :subscriptions_count
  end
end
