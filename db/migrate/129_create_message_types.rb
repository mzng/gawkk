class CreateMessageTypes < ActiveRecord::Migration
  def self.up
    create_table :message_types do |t|
      t.column :name, :string
    end
    
    MessageType.reset_column_information
    share_type = MessageType.create :name => 'share'
    reply_type = MessageType.create :name => 'reply'
    MessageType.create :name => 'bulletin'
    MessageType.create :name => 'comment'
    
    add_column :messages, :message_type_id, :integer
    
    Message.find(:all).each do |message|
      message.update_attribute('message_type_id', (message.reply ? reply_type.id : share_type.id))
    end
    
    remove_column :messages, :reply
  end

  def self.down
    add_column :messages, :reply, :boolean, :default => false, :null => false
    remove_column :messages, :message_type_id
    drop_table :message_types
  end
end
