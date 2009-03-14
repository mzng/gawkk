class CreateTwitterAccounts < ActiveRecord::Migration
  def self.up
    create_table :twitter_accounts do |t|
      t.column :user_id, :integer
      t.column :username, :string
      t.column :password, :string
      t.column :authenticated, :boolean, :default => false, :null => false
      t.column :created_at, :timestamp
    end
  end

  def self.down
    drop_table :twitter_accounts
  end
end
