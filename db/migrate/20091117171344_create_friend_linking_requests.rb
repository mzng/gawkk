class CreateFriendLinkingRequests < ActiveRecord::Migration
  def self.up
    create_table :friend_linking_requests do |t|
      t.integer :user_id
      t.text    :friend_ids
      t.timestamps
    end
    
    JobType.create :name => 'friend_linking', :description => 'Creates mutual follows between Facebook friends.'
  end

  def self.down
    JobType.find_by_name('friend_linking').destroy
    drop_table :friend_linking_requests
  end
end
