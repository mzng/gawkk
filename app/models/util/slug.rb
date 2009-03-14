class Util::Slug
  def self.generate(string, unique = true)
    if string.length > 220
      string = string[0, 220]
    end
    
    if unique
      unique!(trim(string.gsub(/[^a-z0-9]+/i, '-').downcase))
    else
      trim(string.gsub(/[^a-z0-9]+/i, '-').downcase)
    end
  end
  
  def self.trim(string)
    # Trim trailing hyphen from string
    while string[string.length - 1, string.length] == '-'
      string = string.chop
    end
    
    # Trim leading hyphen from string
    while string.length > 0 and string[0, 1] == '-'
      string = string[1, string.length - 1]
    end
    
    string
  end
  
  def self.unique!(string)
    video = Video.find_by_slug(string)
    if video
      i = 0
      begin
        i += 1
      end while Video.count(:conditions => ["slug = ?", string + '-' + i.to_s]) > 0
      string = string + '-' + i.to_s
    end
    string
  end
end