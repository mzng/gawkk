class CreateBlacklistedDomains < ActiveRecord::Migration
  def self.up
    create_table :blacklisted_domains do |t|
      t.column :domain, :string, :default => '', :null => false
      t.column :submit_frame, :boolean, :default => false, :null => false
      t.column :watch_frame, :boolean, :default => false, :null => false
      t.column :video_embed, :boolean, :default => false, :null => false
    end
  end

  def self.down
    drop_table :blacklisted_domains
  end
end
