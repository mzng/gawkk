class AddSuggestedToUsersAndChannels < ActiveRecord::Migration
  def self.up
    add_column :users, :suggested, :boolean, :default => false, :null => false
    add_column :channels, :suggested, :boolean, :default => false, :null => false
  end

  def self.down
    remove_column :channels, :suggested
    remove_column :users, :suggested
  end
end
