class CreateFlagTypes < ActiveRecord::Migration
  def self.up
    create_table :flag_types do |t|
      t.column :name, :string
    end
  end

  def self.down
    drop_table :flag_types
  end
end
