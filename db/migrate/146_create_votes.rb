class CreateVotes < ActiveRecord::Migration
  def self.up
    create_table :votes do |t|
      t.column :user_id, :integer
      t.column :feed_owner, :boolean
      t.column :video_id, :integer
      t.column :value, :integer
      t.column :created_at, :timestamp
    end
    
    add_column :videos, :votes_count, :integer, :default => 0
    add_column :videos, :member_votes_count, :integer, :default => 0
    
    puts "IMPORTANT: Be sure to bootstrap voting data with rake votes:bootstrap"
  end

  def self.down
    remove_column :videos, :member_votes_count
    remove_column :videos, :votes_count
    drop_table :votes
  end
end
