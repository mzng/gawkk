namespace :likes do
	desc "Setup the like data"
	task :bootstrap => :environment do
	  for page in (1..(Vote.count(:all, :conditions => 'feed_owner = false AND value > 0') / 100 + 1)).to_a
	    puts page
	    Vote.find(:all, :conditions => 'feed_owner = false AND value > 0', :limit => 100, :offset => (100 * (page - 1))).each do |vote|
  	    Like.create(:user_id => vote.user_id, :video_id => vote.video_id, :created_at => vote.created_at)
      end
    end
  end
end