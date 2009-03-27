namespace :hulu do
	namespace :generate do
	  desc "Generate missing hulu embed code"
  	task :embed_code => :environment do
  	  processed = 0
  	  for page in (1..(Video.count(:all, :conditions => "(embed_code IS NULL OR embed_code = '') AND url like '%hulu.com%'", :order => 'posted_at desc') / 100 + 1)).to_a
  	    puts page
  	    Video.find(:all, :conditions => "(embed_code IS NULL OR embed_code = '') AND url like '%hulu.com%'", :order => 'posted_at desc', :limit => 100, :offset => (100 * (page - 1)) - processed).each do |video|
    	    video.update_attribute('embed_code', Util::EmbedCode.generate(video, video.url))
    	    puts video.title + ': ' + video.url
    	    
    	    if !video.embed_code.blank?
    	      processed = processed + 1
  	      end
        end
      end
    end
  end
end