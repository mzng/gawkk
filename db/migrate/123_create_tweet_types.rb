class CreateTweetTypes < ActiveRecord::Migration
  def self.up
    create_table :tweet_types do |t|
      t.column :name, :string
      t.column :template, :text
    end
  end

  def self.down
    drop_table :tweet_types
  end
end
