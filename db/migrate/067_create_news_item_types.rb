class CreateNewsItemTypes < ActiveRecord::Migration
  def self.up
    create_table :news_item_types do |t|
      t.column :name, :string
      t.column :template, :text
      t.column :about_user, :boolean
    end
  end

  def self.down
    drop_table :news_item_types
  end
end
