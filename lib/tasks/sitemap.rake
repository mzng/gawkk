require 'erb'
require 'lib/sitemap.rb'

namespace :sitemaps do
  task :static => :environment do
    categories = Category.find(:all, :order => 'name')
    
    categories.each do |category|
      puts "Preparing to generate a sitemap for #{category.name}"

      channels = Channel.in_category(category.id).find(:all, :order => 'name')
      template = File.new('app/views/sitemaps/category.html.erb').read
      html = ERB.new(template, nil, '%').result(binding)
      
      system("rm -f public/sitemaps/#{category.slug}.html")
      File.open("public/sitemaps/#{category.slug}.html", 'a') do |file|
        file.puts html
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
          File.open("log/sitemaps.log", 'a') do |log|
            log.puts "Preparing to generate a sitemap for #{category.name}/#{previous_day.strftime('%Y-%m-%d')}..."
            log.puts " - Querying for #{category.name} videos >= #{previous_day.strftime('%Y-%m-%d')} and < #{end_day.strftime('%Y-%m-%d')}"
          end
          
          videos = Video.find(:all, :conditions => ['category_id = ? AND posted_at >= ? AND posted_at < ?', category.id, previous_day, end_day])
          
          File.open("log/sitemaps.log", 'a') do |log|
            log.puts " - Found #{videos.size} Videos"
          end

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
    system 'rm -f public/sitemap.xml'

    File.open("public/sitemap.xml", 'a') do |file|
      file.puts '<?xml version="1.0" encoding="UTF-8"?>'
      file.puts '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">'

      categories = Category.find(:all, :order => 'name')
    
      categories.each do |category|
        file.puts '<url>'
        file.puts "<loc>#{Util::Routes.category_url(category)}</loc>"
        file.puts "<lastmod>#{Time.now.strftime("%Y-%m-%d")}</lastmod>"
        file.puts "<changefreq>weekly</changefreq>"
        file.puts '<priority>0.5</priority>'
        file.puts '</url>'
      end


      channels = Channel.find(:all, :conditions => { :user_owned => false }, :order => 'name', :include => :user)

      channels.each do |channel|
        file.puts '<url>'
        file.puts "<loc>#{Util::Routes.channel_url(channel)}</loc>"
        file.puts "<lastmod>#{Time.now.strftime("%Y-%m-%d")}</lastmod>"
        file.puts "<changefreq>daily</changefreq>"
        file.puts "<priority>0.7</priority>"
        file.puts '</url>'
      end

      file.puts '</urlset>'
    end
  end
end
