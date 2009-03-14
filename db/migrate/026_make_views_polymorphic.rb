class MakeViewsPolymorphic < ActiveRecord::Migration
  def self.up
    # since we don't care about the views data yet 
    # there is no trouble destroying this table in 
    # order to ultimately make it polymorphic.
    
    execute "DELETE FROM views"
    remove_column :views, :video_id
    add_column    :views, :viewable_type, :string
    add_column    :views, :viewable_id,   :integer, :references => nil
    
    # add views_count to channels (we already have it on videos)
    add_column :channels, :views_count, :integer, :default => 0, :null => false
  end

  def self.down
    remove_column :channels, :views_count
    remove_column :views, :viewable_id
    remove_column :views, :viewable_type
    add_column    :views, :video_id, :integer
  end
end
