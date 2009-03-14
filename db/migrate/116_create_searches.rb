class CreateSearches < ActiveRecord::Migration
  def self.up
    create_table :searches do |t|
      t.column :search_type_id, :integer
      t.column :query, :string
      t.column :user_id, :integer
      t.column :created_at, :timestamp
    end
  end

  def self.down
    drop_table :searches
  end
end
