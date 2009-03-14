class CreateSuggestions < ActiveRecord::Migration
  def self.up
    create_table :suggestions do |t|
      t.integer :user_id, :channel_id
      t.string :suggestion_type, :url
      t.boolean :processed, :default => false, :null => false
      t.timestamps
    end
  end

  def self.down
    drop_table :suggestions
  end
end
