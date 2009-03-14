class CreateTweets < ActiveRecord::Migration
  def self.up
    create_table :tweets do |t|
      t.column :twitter_account_id, :integer
      t.column :tweet_type_id, :integer
      t.column :auth_code, :string
      t.column :reportable_type, :string
      t.column :reportable_id, :integer, :references => nil
      t.column :published, :boolean, :default => false, :null => false
      t.column :created_at, :timestamp
    end
  end

  def self.down
    drop_table :tweets
  end
end
