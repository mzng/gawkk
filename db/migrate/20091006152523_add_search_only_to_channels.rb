class AddSearchOnlyToChannels < ActiveRecord::Migration
  def self.up
    add_column :channels, :search_only, :boolean, :default => false, :null => false
    
    Channel.reset_column_information
    Channel.all(:conditions => {:user_owned => false}).each do |channel|
      channel.update_attribute(:search_only, (Feed.count(:all, :conditions => {:owned_by_id => channel.user_id}) == 0))
    end
  end

  def self.down
    remove_column :channels, :search_only
  end
end
