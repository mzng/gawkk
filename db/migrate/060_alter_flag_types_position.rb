class AlterFlagTypesPosition < ActiveRecord::Migration
  def self.up
    #execute "ALTER TABLE flag_types ALTER COLUMN position DROP NOT NULL"
  end

  def self.down
    #execute "ALTER TABLE flag_types ALTER COLUMN position SET NOT NULL"
  end
end
