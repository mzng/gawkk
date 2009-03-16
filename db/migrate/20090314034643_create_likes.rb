class CreateLikes < ActiveRecord::Migration
  def self.up
    create_table :likes do |t|
      t.column :user_id, :integer
      t.column :video_id, :integer
      t.timestamps
    end
    
    add_column :videos, :likes_count, :integer, :default => 0
    
    puts "IMPORTANT: Be sure to bootstrap like data with rake likes:bootstrap"
  end

  def self.down
    drop_table :likes
  end
end
