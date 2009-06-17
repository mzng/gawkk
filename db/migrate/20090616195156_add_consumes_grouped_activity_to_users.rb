class AddConsumesGroupedActivityToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :consumes_grouped_activity, :boolean, :default => true, :null => false
  end

  def self.down
    remove_column :users, :consumes_grouped_activity
  end
end
