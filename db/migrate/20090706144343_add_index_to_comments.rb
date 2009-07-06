class AddIndexToComments < ActiveRecord::Migration
  def self.up
    add_index :comments, [:commentable_type, :commentable_id, :user_id], :name => 'index_comments_type_user'
  end

  def self.down
    remove_index :comments, [:commentable_type, :commentable_id, :user_id], :name => 'index_comments_type_user'
  end
end
