class CreateParameters < ActiveRecord::Migration
  def self.up
    create_table :parameters do |t|
      t.column :name, :string
      t.column :value, :string
    end
    Parameter.reset_column_information
    
    Parameter.create :name => 'allow_feed_imports', :value => 'true'
  end

  def self.down
    drop_table :parameters
  end
end
