class AddEmailConfirmationToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :email_confirmation_auth_code, :string
    add_column :users, :email_confirmed_at, :timestamp
  end

  def self.down
    remove_column :users, :email_confirmed_at
    remove_column :users, :email_confirmation_auth_code
  end
end
