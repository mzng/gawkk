class CreateUsers < ActiveRecord::Migration
  def self.up
    create_table :users do |t|
      t.column :administrator, :boolean, :default => false
      t.column :username, :string
      t.column :hashed_password, :string, :size => 40
      t.column :name, :string
      t.column :email, :string
      t.column :birthday, :date
      t.column :location, :string
      t.column :last_login_at, :timestamp
      t.column :created_at, :timestamp
    end
  end

  def self.down
    drop_table :users
  end
end
