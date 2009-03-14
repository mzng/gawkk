class AddPasswordResetToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :password_reset_auth_code, :string
    add_column :users, :password_reset_expires_at, :timestamp
  end

  def self.down
    remove_column :users, :password_reset_expires_at
    remove_column :users, :password_reset_auth_code
  end
end
