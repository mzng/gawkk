class CreateStagedSearches < ActiveRecord::Migration
  def self.up
    create_table :staged_searches do |t|
      t.string    :query, :null => false
      t.integer   :count, :null => false
    end

    add_index :staged_searches, :query
  end

  def self.down
    drop_table :staged_searches
  end
end
