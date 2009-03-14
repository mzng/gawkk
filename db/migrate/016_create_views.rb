class CreateViews < ActiveRecord::Migration
  def self.up
    create_table :views do |t|
      t.column :video_id, :integer
      t.column :user_id, :integer
    end
    
    add_column :videos, :views_count, :integer, :default => 0, :null => false
  end

  def self.down
    drop_table :views
  end
end
