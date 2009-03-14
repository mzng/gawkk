class AddCreatedAtToFlags < ActiveRecord::Migration
  def self.up
    add_column :flags, :created_at, :timestamp
  end

  def self.down
    remove_column :flags, :created_at
  end
end
