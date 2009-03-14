class MakeSavesByChannelNotUser < ActiveRecord::Migration
  def self.up
    # since we don't care about the saves data yet 
    # there is no trouble destroying this table in 
    # order to ultimately make it polymorphic.
    
    execute "DELETE FROM saves"
    remove_column :saves, :user_id
    remove_column :users, :saves_count
    add_column    :saves, :channel_id, :integer
    
    # add saves_count to channels (we already have it on videos)
    add_column :channels, :saves_count, :integer, :default => 0, :null => false
  end

  def self.down
    remove_column :channels, :saves_count
    remove_column :saves, :channel_id
    add_column    :users, :saves_count, :integer
    add_column    :saves, :user_id, :integer
  end
end
