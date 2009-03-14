class CreateMyspaceUninstalls < ActiveRecord::Migration
  def self.up
    create_table :myspace_uninstalls do |t|
      t.column :myspace_id, :integer, :references => nil
      t.column :created_at, :timestamp
    end
  end

  def self.down
    drop_table :myspace_uninstalls
  end
end
