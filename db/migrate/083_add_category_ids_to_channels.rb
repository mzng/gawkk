class AddCategoryIdsToChannels < ActiveRecord::Migration
  def self.up
    add_column :channels, :category_ids, :string, :default => '', :null => false
    Channel.reset_column_information
    
    Channel.find(:all, :include => :user, :conditions => 'users.feed_owner = true').each do |channel|
      channel.categorize!
    end
  end

  def self.down
    remove_column :channels, :category_ids
  end
end
