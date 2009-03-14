class AddThreadIdToComments < ActiveRecord::Migration
  def self.up
    add_column :comments, :thread_id, :string, :references => nil
  end

  def self.down
    remove_column :comments, :thread_id
  end
end
