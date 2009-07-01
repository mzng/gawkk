class AddIndexForStateToJobs < ActiveRecord::Migration
  def self.up
    add_index :jobs, :state
  end

  def self.down
    remove_index :jobs, :state
  end
end
