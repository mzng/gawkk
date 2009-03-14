class CreateChannels < ActiveRecord::Migration
  def self.up
    create_table :channels do |t|
      t.column :name,         :string
      t.column :slug,         :string
      t.column :description,  :text, :null => false
      t.column :user_id,      :integer
      t.column :featured,     :boolean, :default => false, :null => false
      t.column :created_at,   :timestamp
    end
    
    User.find(:all).each do |user|
      channel = Channel.new
      channel.name    = 'The ' + user.username + ' Channel'
      channel.user_id = user.id
      channel.save
    end
  end

  def self.down
    drop_table :channels
  end
end
