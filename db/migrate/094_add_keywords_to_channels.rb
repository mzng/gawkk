class AddKeywordsToChannels < ActiveRecord::Migration
  def self.up
    add_column :channels, :keywords, :text, :null => false, :default => ''
  end

  def self.down
    remove_column :channels, :keywords
  end
end
