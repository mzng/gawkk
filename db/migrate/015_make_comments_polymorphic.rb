class MakeCommentsPolymorphic < ActiveRecord::Migration
  def self.up
    # since we don't care about the comments data yet 
    # there is no trouble destroying this table in 
    # order to ultimately make it polymorphic.
    
    execute "DELETE FROM comments"
    remove_column :comments, :video_id
    add_column :comments, :commentable_type, :string
    add_column :comments, :commentable_id, :integer, :references => nil
  end

  def self.down
    add_column :comments, :video_id, :integer
  end
end
