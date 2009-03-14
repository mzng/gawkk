class RecreateSavesTable < ActiveRecord::Migration
  def self.up
    # originally, the saves table was a simple intersection table 
    # and did not contain an id field. this proved unstable when 
    # performing certain queries using ActiveRecord. since we like 
    # our configuration data (including feeds and categories) but 
    # do not yet care about our saves, we can simply drop our saves 
    # table and re-create it the way it should have been created 
    # from the start.
    
    drop_table :saves
    
    create_table :saves do |t|
      t.column :user_id, :integer
      t.column :video_id, :integer
      t.column :created_at, :timestamp
    end
    
    execute "UPDATE videos SET promoted_at = NULL"
    execute "UPDATE videos SET saves_count = 0"
  end

  def self.down
    # not necessary
  end
end