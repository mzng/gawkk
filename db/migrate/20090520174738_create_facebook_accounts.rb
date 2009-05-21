class CreateFacebookAccounts < ActiveRecord::Migration
  def self.up
    create_table :facebook_accounts do |t|
      t.column :user_id, :integer
      t.column :facebook_user_id, :string, :references => nil
      t.timestamps
    end
  end

  def self.down
    drop_table :facebook_accounts
  end
end
