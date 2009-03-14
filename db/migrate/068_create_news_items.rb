class CreateNewsItems < ActiveRecord::Migration
  def self.up
    create_table :news_items do |t|
      t.column :news_item_type_id, :integer
      t.column :user_id, :integer
      t.column :reportable_type, :string
      t.column :reportable_id, :integer, :references => nil
      t.column :message, :text
    end
  end

  def self.down
    drop_table :news_items
  end
end
