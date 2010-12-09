module Util
  class Routes
    def root_url
      "http://#{BASE_URL}"
    end

    def self.channel_url(channel, user = nil, page = nil, newest = nil)
      user ||= channel.user
      url = "http://"
      subdomain = false

      splits = channel.category_ids.split ' '
      
      splits.each do |s|
        if s == '7'
          url += "tv."
          subdomain = true

          break
        elsif s == '26'
          url += "movies."
            subdomain = true
          break
        end
      end

      unless subdomain
        if splits[0]
          category = Category.find(splits[0])
        else 
          category = Category.find_by_slug("uncategorized")
        end
      end

      url += "#{BASE_URL}/"
      url += "#{category.slug}/" unless subdomain
      url += "#{user.slug}"
      url += "?page=#{page}" if page
      url += "?newest=true" if newest && !page
      url += "&newest=true" if newest && page

      url
    end

    def self.category_url(category, newest = nil)
      url = "http://"
      subdomain = false
      if category.slug == 'television-shows'
        url += "tv."
        subdomain = true
      elsif category.slug == 'movies-previews-trailers'      
        url += "movies."
        subdomain = true
      end

      url += BASE_URL

      if subdomain
      
      else
        url += "/topics/#{category.slug}"
      end

      url
    end
  end
end
