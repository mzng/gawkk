#select id, posted_at, likes_count, log10(likes_count - dislikes_count), (datediff(posted_at, '2007-01-01 00:00:00.0000')/500), log10(likes_count - dislikes_count) + (datediff(posted_at, '2007-01-01 00:00:00.0000')/300) from videos where likes_count - dislikes_count > 1 order by 
#log10(likes_count - dislikes_count) + (datediff(posted_at, '2007-01-01 00:00:00.0000')/500) desc


namespace "popularity" do
  desc "populates the popularity column of videos"
  task "recreate" => :environment do
   ActiveRecord::Base.connection.execute "
      UPDATE videos 
      SET popularity_score = (log10(likes_count - dislikes_count) + (datediff(posted_at, '2007-01-01 00:00:00.0000')/300)) * 10000
      WHERE likes_count > dislikes_count"
  end
end
