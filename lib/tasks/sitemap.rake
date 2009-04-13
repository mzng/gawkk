require 'lib/sitemap.rb'

namespace :sitemaps do
	desc "Re-generates XML Sitemap files"
	task :generate => :environment do
	  count = 0
    sitemap_count = 0
    
    index   = SitemapIndex.new
    sitemap = nil
    
    Video.find_in_batches(:batch_size => 1000) { |videos|
      puts "sitemap_count: " + sitemap_count.to_s
      puts "count: " + count.to_s
      puts ""
      
      if count % 50 == 0
        # Write queued up sitemap to disk
        if !sitemap.nil?
          index.add_sitemap(sitemap)
          
          file = File.new(File.join(RAILS_ROOT, "public/sitemap_#{sitemap_count.to_s}.xml"), 'w')
          file.write sitemap.to_xml
          file.close

          system("gzip #{File.join(RAILS_ROOT, 'public/sitemap_' + sitemap_count.to_s + '.xml')}")
        end
        
        # Setup a new sitemap
        sitemap_count = sitemap_count + 1
        sitemap = Sitemap.new("http://www.gawkk.com/sitemap_#{sitemap_count.to_s}.xml.gz")
      end
      
      # Add videos to current sitemap
      videos.each { |video|
        sitemap.add_url("http://www.gawkk.com/#{video.slug}/discuss")
      }
      
      count = count + 1
    }
    
    
    # Write final sitemap to disk
    index.add_sitemap(sitemap)
    
    file = File.new(File.join(RAILS_ROOT, "public/sitemap_#{sitemap_count.to_s}.xml"), 'w')
    file.write sitemap.to_xml
    file.close

    system("gzip #{File.join(RAILS_ROOT, 'public/sitemap_' + sitemap_count.to_s + '.xml')}")
    
    
    # Write sitemap index to disk
    file = File.new(File.join(RAILS_ROOT, "public/sitemap_index.xml"), 'w')
    file.write index.to_xml
    file.close

    system("gzip #{File.join(RAILS_ROOT, 'public/sitemap_index.xml')}")
    
    if Rails.env == 'production'
      system("rm -f /var/www/apps/gawkk/shared/sitemaps/*.xml.gz")
      system("cp /var/www/apps/gawkk/current/public/sitemap_*.xml.gz /var/www/apps/gawkk/shared/sitemaps/")
    end
  end
end