class RemoveLegacyTables < ActiveRecord::Migration
  def self.up
    drop_table :myspace_includes
    drop_table :myspace_installs
    drop_table :myspace_uninstalls
    
    drop_table :threshold_adjustments
    drop_table :threshold_types
    
    drop_table :saves_defunt
  end

  def self.down
  end
end
