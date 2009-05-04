class Util::Scrub
  def self.query(q, remove_stop_words = false, trim = true)
    q = q.gsub(/[^\w|^ ]/, '')
    
    if remove_stop_words
      stop_words = ['a','about','above','across','after','again','against','all','almost','alone','along','a','eady','also','although','always','among','an','and','another','any','anybody','anyone','anything','anywhere','are','area','areas','around','as','ask','asked','asking','asks',',','away','b','back','backed','backing','backs','be','became','because','become','becomes','been','before','began','behind','being','beings','best','better','between','big','both','but','by','c','came','can','cannot','case','cases','certain','certainly','clear','clea','y','come','could','d','did','differ','different','differently','do','does','done','down','down','downed','downing','downs','during','e','each','early','either','end','ended','ding','ends','enough','even','evenly','ever','every','everybody','everyone','everything','everywhere','f','face','faces','fact','facts','far','felt','few','find','finds','first','for','four','from','full','fully','further','furthered','furthering','furthers','g','g','e','general','generally','get','gets','give','given','gives','go','going','good','goods','got','great','greater','greatest','group','grouped','grouping','groups','h','had','has','have','having','he','her','here','herself','high','higher','highest','h','himself','his','how','however','i','if','important','in','interest','interested','in','resting','interests','into','is','it','its','itself','j','just','k','keep','keeps','ki','new','know','known','knows','l','large','largely','last','later','latest','least','less','let','lets','like','likely','long','longer','longest','m','made','make','making','man','many','may','me','member','members','men','might','more','most','mostly','mr','mrs','much','must','my','myself','n','necessary','need','needed','needing','needs','never','w','new','newer','newest','next','no','nobody','non','noone','not','nothing','now','now','re','number','numbers','o','of','off','often','old','older','oldest','on','once','one','only','open','opened','opening','opens','or','order','ordered','ordering','orders','oth','others','our','out','over','p','part','parted','parting','parts','per','perhaps','pl','e','places','point','pointed','pointing','points','possible','present','presented','pr','enting','presents','problem','problems','put','puts','q','quite','r','rather','really','right','right','room','rooms','s','said','same','saw','say','says','second','seconds','e','seem','seemed','seeming','seems','sees','several','shall','she','should','show','sh','ed','showing','shows','side','sides','since','small','smaller','smallest','so','some','somebody','someone','something','somewhere','state','states','still','still','such','sure','t','take','taken','than','that','the','their','them','then','there','therefore','these','they','thing','things','think','thinks','this','those','though','thought','thoughts','three','through','thus','to','today','together','too','took','toward','turn','turned','t','ning','turns','two','u','under','until','up','upon','us','use','used','uses','v','very','video','w','want','wanted','wanting','w','ts','was','way','ways','we','well','wells','went','were','what','when','where','whether','which','while','who','whole','whose','why','will','with','within','without','work','word','working','works','would','x','y','year','years','yet','you','young','younger','youn','st','your','yours','z']
      words = q.split
      words.each_with_index do |word, i|
        # words.delete(word) if stop_words.include?(word)
        words[i] = 'x' if stop_words.include?(word)
      end
      
      words.delete('x')
      
      if trim and words.length > 4
        q = words[0, 4].join(' ')
      else
        q = words.join(' ')
      end
    end
    
    return q
  end
  
  def self.title(title)
    if !title.nil?
      title = title.strip
      
      # Strip known site leading and trailing phrases
      title = Util::Scrub.strip(title, 'BBC NEWS | ', :leading)
      title = Util::Scrub.strip(title, 'Breitbart.tv &raquo; ', :leading)
      title = Util::Scrub.strip(title, ' - CollegeHumor video', :trailing)
      title = Util::Scrub.strip(title, 'Dailymotion - ', :leading)
      title = Util::Scrub.strip(title, 'Hulu - ', :leading)
      title = Util::Scrub.strip(title, ' - IFILM', :trailing)
      title = Util::Scrub.strip(title, 'LiveLeak.com - ', :leading)
      title = Util::Scrub.strip(title, ' - MySpace Video', :trailing)
      title = Util::Scrub.strip(title, 'Special Reports | ', :leading)
      title = Util::Scrub.strip(title, ' | Video on TED.com', :trailing)
      title = Util::Scrub.strip(title, ' on Vimeo', :trailing)
      title = Util::Scrub.strip(title, 'YouTube - ', :leading)
      
      # Cleanup html
      title = title.gsub(/&amp;/, '&')
      title = title.gsub(/&apos;/, '\'')
      title = title.gsub(/&nbsp;/, ' ')
      title = Hpricot(title).to_plain_text
      
      return title
    else
      return ''
    end
  end
  
  def self.strip(title, phrase, position)
    if position == :leading and title[0, phrase.length] == phrase
      title = title[phrase.length, title.length]
    elsif position == :trailing and title[title.length - phrase.length, title.length] == phrase
      title = title[0, title.length - phrase.length]
    end
    
    return title
  end
  
  def self.html(html, okTags='a href, b, br, i, p')
    # no closing tag necessary for these
    soloTags = ["br","hr"]

    # Build hash of allowed tags with allowed attributes
    tags = okTags.downcase().split(',').collect!{ |s| s.split(' ') }
    allowed = Hash.new
    tags.each do |s|
      key = s.shift
      allowed[key] = s
    end

    # Analyze all <> elements
    stack = Array.new
    result = html.gsub( /(<.*?>)/m ) do | element |
      if element =~ /\A<\/(\w+)/ then
        # </tag>
        tag = $1.downcase
        if allowed.include?(tag) && stack.include?(tag) then
          # If allowed and on the stack
          # Then pop down the stack
          top = stack.pop
          out = "</#{top}>"
          until top == tag do
            top = stack.pop
            out << "</#{top}>"
          end
          out
        end
      elsif element =~ /\A<(\w+)\s*\/>/
        # <tag />
        tag = $1.downcase
        if allowed.include?(tag) then
          "<#{tag} />"
        end
      elsif element =~ /\A<(\w+)/ then
        # <tag ...>
        tag = $1.downcase
        if allowed.include?(tag) then
          if ! soloTags.include?(tag) then
            stack.push(tag)
          end
          if allowed[tag].length == 0 then
            # no allowed attributes
            "<#{tag}>"
          else
            # allowed attributes?
            out = "<#{tag}"
            while ( $' =~ /(\w+)=("[^"]+")/ )
              attr = $1.downcase
              valu = $2
              if allowed[tag].include?(attr) then
                out << " #{attr}=#{valu}"
              end
            end
            out << ">"
          end
        end
      end
    end

    # eat up unmatched leading >
    while result.sub!(/\A([^<]*)>/m) { $1 } do end

    # eat up unmatched trailing <
    while result.sub!(/<([^>]*)\Z/m) { $1 } do end

    # clean up the stack
    if stack.length > 0 then
      result << "</#{stack.reverse.join('></')}>"
    end

    result
  end
  
  
  def self.url(url)
    url = Util::Scrub.truveo_url(url)
    url = Util::Scrub.youtube_url(url)
    return url
  end
  
  def self.truveo_url(possible_truveo_url)
    begin
      # Trim truveo url
      if possible_truveo_url.downcase[/^(http|https):\/\/xml\.truveo\.com\//]
        uri = URI.parse(possible_truveo_url)
        url = uri.scheme + '://' + uri.host + uri.path
        uri.query.split('&').each_with_index do |p, i|
          url = url.concat('?') if i == 0
          if p and p.length > 0 and p[0, 1] == 'i'
            url = url.concat('&') if i > 0
            url = url.concat(p)
          end
        end
        if url.index('i=')
          return url
        end
      end
      return possible_truveo_url
    rescue
      return possible_truveo_url
    end
  end
  
  def self.youtube_url(possible_youtube_url)
    begin
      # Clean up YouTube url
      if possible_youtube_url.downcase[/^(http|https):\/\/(.*)?youtube\.com\//]
        url = possible_youtube_url[0, possible_youtube_url.index('?')]
        query = possible_youtube_url[possible_youtube_url.index('?') + 1, possible_youtube_url.length]
        query.split('&').each_with_index do |p, i|
          url = url.concat('?') if i == 0
          if p and p.length > 0 and p[0, 1] == 'v'
            url = url.concat('&') if i > 0
            url = url.concat(p)
          end
        end
        if url.index('v=')
          return url
        end
      end
      return possible_youtube_url
    rescue
      return possible_youtube_url
    end
  end
  
  
  def self.follow_truveo_url(url)
    if url.downcase[/^(http|https):\/\/xml\.truveo\.com\//]
      html = Hpricot(open(url))
      if html.at('meta') and html.at('meta')['content']
        url = html.at('meta')['content'][6, html.at('meta')['content'].length - 2]
      end
    end
    return url
  rescue
    return url
  end
end