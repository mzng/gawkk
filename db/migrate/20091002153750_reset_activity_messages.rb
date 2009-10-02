class ResetActivityMessages < ActiveRecord::Migration
  def self.up
    drop_table :activity_messages
    
    create_table :activity_messages, :id => false do |t|
      t.column :user_id, :integer
      t.column :news_item_id, :integer
      t.column :reportable_type, :string
      t.column :reportable_id, :integer, :references => nil
      t.column :hidden, :boolean, :default => false, :null => false
      t.timestamps
    end
    
    add_index :activity_messages, [:user_id, :hidden, :reportable_type, :reportable_id], :name => 'index_activity_messages_update'
    add_index :activity_messages, [:user_id, :hidden, :news_item_id], :name => 'index_activity_messages_select'
    
    default = User.find_by_username('default')
    
    NewsItem.find(:all, :conditions => ['user_id IN (?) AND created_at > ?', User.default_followings.collect{|u| u.id}, 60.days.ago], :order => 'created_at ASC').each do |news_item|
      news_item.generate_message_for_user!(default)
    end
  end

  def self.down
  end
end
