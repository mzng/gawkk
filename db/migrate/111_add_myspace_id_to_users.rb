class AddMyspaceIdToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :myspace_id, :integer, :references => nil
  end

  def self.down
    remove_column :users, :myspace_id
  end
end
