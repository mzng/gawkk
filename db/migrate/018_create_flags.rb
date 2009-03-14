class CreateFlags < ActiveRecord::Migration
  def self.up
    create_table :flags do |t|
      t.column :flag_type_id, :integer
      t.column :user_id, :integer
      t.column :video_id, :integer
    end
  end

  def self.down
    drop_table :flags
  end
end
