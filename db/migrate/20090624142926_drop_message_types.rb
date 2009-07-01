class DropMessageTypes < ActiveRecord::Migration
  def self.up
    drop_table :message_types
  end

  def self.down
  end
end
