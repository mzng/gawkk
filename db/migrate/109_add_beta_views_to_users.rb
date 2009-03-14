class AddBetaViewsToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :beta_views, :boolean, :default => false, :null => false
  end

  def self.down
    remove_column :users, :beta_views
  end
end
