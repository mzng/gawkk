class AddSessionIdToViews < ActiveRecord::Migration
  def self.up
    add_column :views, :session_id, :string, :references => nil
  end

  def self.down
    remove_column :views, :session_id
  end
end
