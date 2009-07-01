class CreateActivityMessages < ActiveRecord::Migration
  def self.up
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
  end

  def self.down
    drop_table :activity_messages
  end
end
