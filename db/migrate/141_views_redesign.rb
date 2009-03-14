class ViewsRedesign < ActiveRecord::Migration
  def self.up
    View.delete_all
    execute "ALTER TABLE views AUTO_INCREMENT = 1"
    
    add_column :views, :current_path, :text
    add_column :views, :user_agent, :text
    add_column :views, :created_at, :timestamp
  end

  def self.down
    remove_column :views, :created_at
    remove_column :views, :user_agent
    remove_column :views, :current_path
  end
end
