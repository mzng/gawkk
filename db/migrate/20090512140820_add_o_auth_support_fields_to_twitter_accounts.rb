class AddOAuthSupportFieldsToTwitterAccounts < ActiveRecord::Migration
  def self.up
    add_column :twitter_accounts, :twitter_user_id, :string, :references => nil
    add_column :twitter_accounts, :access_token, :string
    add_column :twitter_accounts, :access_secret, :string
  end

  def self.down
    remove_column :twitter_accounts, :access_secret
    remove_column :twitter_accounts, :access_token
    remove_column :twitter_accounts, :twitter_user_id
  end
end
