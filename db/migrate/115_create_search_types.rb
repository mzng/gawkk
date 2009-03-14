class CreateSearchTypes < ActiveRecord::Migration
  def self.up
    create_table :search_types do |t|
      t.column :name, :string
    end
    
    SearchType.reset_column_information
    SearchType.create :name => 'all'
    SearchType.create :name => 'channel'
    SearchType.create :name => 'member'
    SearchType.create :name => 'video'
    SearchType.create :name => 'youtube'
  end

  def self.down
    drop_table :search_types
  end
end
