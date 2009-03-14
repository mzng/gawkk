class AddCookieHashToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :cookie_hash, :string
  end

  def self.down
    remove_column :users, :cookie_hash
  end
end
