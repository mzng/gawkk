class AddPopularityToVideos < ActiveRecord::Migration
  def self.up
    add_column :videos, :popularity_score, :integer
    add_index :videos, :popularity_score
  end

  def self.down
    remove_column :videos, :popularity_score
  end
end
