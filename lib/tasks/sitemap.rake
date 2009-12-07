require 'erb'
require 'lib/sitemap.rb'

namespace :sitemaps do
  task :static => :environment do
    end_day = Time.parse(Time.now.strftime('%Y-%m-%d')) + 5.hours
    previous_day = Time.parse((Time.now - 1.day).strftime('%Y-%m-%d')) + 5.hours
    
    categories = Category.find(:all, :conditions => 'allowed_on_front_page = true', :order => 'name')
    
    categories.each do |category|
      puts "Preparing to generate a sitemap for #{category.name}/#{end_day.strftime('%Y-%m-%d')}..."
      puts " - Querying for #{category.name} videos between #{previous_day.strftime('%Y-%m-%d')} and #{end_day.strftime('%Y-%m-%d')}"
      videos = Video.find(:all, :conditions => ['category_id = ? AND posted_at >= ? AND posted_at < ?', category.id, previous_day, end_day])
      puts " - Found #{videos.size} Videos"
      
      template = File.new('app/views/sitemaps/category.html.erb').read
      html = ERB.new(template, nil, '%').result(binding)
      
      if videos.size > 0
        system("rm -f public/sitemaps/#{category.slug}/#{previous_day.strftime('%Y-%m-%d')}.html")
        File.open("public/sitemaps/#{category.slug}/#{previous_day.strftime('%Y-%m-%d')}.html", 'a') do |file|
          file.puts html
    	  end
      end
    end
    
    template = File.new('app/views/sitemaps/index.html.erb').read
    html = ERB.new(template, nil, '%').result(binding)
    
    system("rm -f public/sitemaps/index.html")
    File.open("public/sitemaps/index.html", 'a') do |file|
      file.puts html
	  end
  end
  
  namespace :back do
    task :static => :environment do
      categories = Category.find(:all, :conditions => 'allowed_on_front_page = true', :order => 'name')
      
      for i in (1..1071)
        end_day = Time.parse((Time.now - i.days).strftime('%Y-%m-%d')) + 5.hours
        previous_day = Time.parse((Time.now - (i + 1).days).strftime('%Y-%m-%d')) + 5.hours

        categories.each do |category|
          puts "Preparing to generate a sitemap for #{category.name}/#{previous_day.strftime('%Y-%m-%d')}..."
          puts " - Querying for #{category.name} videos >= #{previous_day.strftime('%Y-%m-%d')} and < #{end_day.strftime('%Y-%m-%d')}"
          videos = Video.find(:all, :conditions => ['category_id = ? AND posted_at >= ? AND posted_at < ?', category.id, previous_day, end_day])
          puts " - Found #{videos.size} Videos"

          template = File.new('app/views/sitemaps/category.html.erb').read
          html = ERB.new(template, nil, '%').result(binding)

          if videos.size > 0
            system("rm -f public/sitemaps/#{category.slug}/#{previous_day.strftime('%Y-%m-%d')}.html")
            File.open("public/sitemaps/#{category.slug}/#{previous_day.strftime('%Y-%m-%d')}.html", 'a') do |file|
              file.puts html
        	  end
          end
        end
      end
    end
  end
  
	desc "Re-generates XML Sitemap files"
	task :generate => :environment do
	  if Rails.env.production?
  	  system("rm -f /var/www/apps/gawkk/current/public/sitemap_*.xml.gz")
	  end
	  
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
          sitemap.loc = "http://www.gawkk.com/sitemap_#{sitemap_count.to_s}.xml.gz"
          index.add_sitemap(sitemap)
          
          file = File.new(File.join(RAILS_ROOT, "public/sitemap_#{sitemap_count.to_s}.xml"), 'w')
          file.write sitemap.to_xml
          file.close
          
          system("gzip #{File.join(RAILS_ROOT, 'public/sitemap_' + sitemap_count.to_s + '.xml')}")
        end
        
        # Setup a new sitemap
        sitemap_count = sitemap_count + 1
        sitemap = Sitemap.new
      end
      
      # Add videos to current sitemap
      videos.each { |video|
        sitemap.add_url("http://www.gawkk.com/#{video.slug}/discuss")
      }
      
      count = count + 1
    }
    
    
    # Write final sitemap to disk
    sitemap.loc = "http://www.gawkk.com/sitemap_#{sitemap_count.to_s}.xml.gz"
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
    
    if Rails.env.production?
      system("rm -f /var/www/apps/gawkk/shared/sitemaps/*.xml.gz")
      system("cp /var/www/apps/gawkk/current/public/sitemap_*.xml.gz /var/www/apps/gawkk/shared/sitemaps/")
    end
  end
end