class AddHighlightColorToFlagTypes < ActiveRecord::Migration
  def self.up
    add_column :flag_types, :highlight_color, :string
  end

  def self.down
    remove_column :flag_types, :highlight_color
  end
end
