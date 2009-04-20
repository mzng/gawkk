class Util::EmbedCode
  def self.generate(video, url)
    video.embed_code = Util::EmbedCode.scrub(video.embed_code)
    
    if video.embed_code.blank?
      video.embed_code = ''
      video.swf_url = ''

      begin
        if url[/^(http|https):\/\/(.*)?hulu\.com\//] # *.hulu.com
          doc = Hpricot(open(url))
          links = (doc/"head link")
          if links.size > 0
            links.each do |link|
              if link[:rel] and link[:rel] == 'video_src' and link[:href]
                video.swf_url = link[:href]
                video.embed_code = "<object class=\"generated-by-gawkk\" width=\"630\" height=\"365\"><param name=\"movie\" value=\"#{video.swf_url}\"></param><embed src=\"#{video.swf_url}\" type=\"application/x-shockwave-flash\"  width=\"630\" height=\"365\"></embed></object>"
              end
            end
          end
          
        elsif url[/^(http|https):\/\/(.*)?youtube\.com\//] # *.youtube.com
          if !url.index('v=', url.index('?') + 1).nil?
            id = url[/v=[\w-]+/][2, url[/v=[\w-]+/].length]
            video.embed_code  = "<object width=\"500\" height=\"415\"><param name=\"movie\" value=\"http://www.youtube.com/v/#{id}\"></param><param name=\"wmode\" value=\"transparent\"></param><embed src=\"http://www.youtube.com/v/#{id}\" type=\"application/x-shockwave-flash\" wmode=\"transparent\" width=\"500\" height=\"415\"></embed></object>"
            video.swf_url     = "http://www.youtube.com/v/#{id}"
          end
        elsif url[/^(http|https):\/\/video\.google\.([a-z]*)\//] # video.google.*
          if !url.index('docid=', url.index('videoplay?') + 10).nil?
            id = url[/docid=[\w-]+/][6, url[/docid=[\w-]+/].length]
            video.embed_code  = "<embed style=\"width:500px; height:415px;\" id=\"VideoPlayback\" type=\"application/x-shockwave-flash\" src=\"http://video.google.com/googleplayer.swf?docId=#{id}&hl=en\" flashvars=\"\"> </embed>"
            video.swf_url     = "http://video.google.com/googleplayer.swf?docId=#{id}&hl=en"
          end
        elsif url[/^(http|https):\/\/(.*)?ifilm\.com\//] # *.ifilm.com
          if !url.index('/video/').nil?
            id = url[/\/video\/\d+/][7, url[/\/video\/\d+/].length]
            video.embed_code  = "<embed allowScriptAccess=\"never\" width=\"500\" height=\"415\" src=\"http://www.ifilm.com/efp\" quality=\"high\" bgcolor=\"000000\" name=\"efp\" align=\"middle\" type=\"application/x-shockwave-flash\" pluginspage=\"http://www.macromedia.com/go/getflashplayer\" flashvars=\"flvbaseclip=#{id}\" ></embed>"
            video.swf_url     = "http://www.ifilm.com/efp?flvbaseclip=#{id}"
          end
        elsif url[/^(http|https):\/\/(.*)?revver\.com\//] # *.revver.com
          if !url.index('/watch/').nil?
            id = url[/\/watch\/\d+/][7, url[/\/watch\/\d+/].length]
            video.embed_code  = "<embed type=\"application/x-shockwave-flash\" src=\"http://flash.revver.com/player/1.0/player.swf\" pluginspage=\"http://www.macromedia.com/go/getflashplayer\" scale=\"noScale\" salign=\"TL\" bgcolor=\"#000000\" flashvars=\"mediaId=#{id}&affiliateId=0&allowFullScreen=true\" allowfullscreen=\"true\" height=\"392\" width=\"480\"></embed>"
            video.swf_url     = "http://flash.revver.com/player/1.0/player.swf?mediaId=#{id}&affiliateId=0&allowFullScreen=true"
          end
        elsif url[/^(http|https):\/\/(.*)?myspace\.com\//] # *.myspace.com
          if !url.index('VideoID').nil?
            id = url[/VideoID=\d+/][8, url[/VideoID=\d+/].length]
            video.embed_code  = "<embed src=\"http://lads.myspace.com/videos/vplayer.swf\" flashvars=\"m=#{id}&v=2&type=video\" type=\"application/x-shockwave-flash\" width=\"430\" height=\"346\"></embed>"
            video.swf_url     = "http://lads.myspace.com/videos/vplayer.swf?m=#{id}&v=2&type=video"
          end
        elsif url[/^(http|https):\/\/(.*)?veoh\.com\//] # *.veoh.com
          if !url.index('/videos/').nil?
            id = url[/\/videos\/[\w-]+(\?|\#)?/][8, url[/\/videos\/[\w-]+(\?|\#)?/].length - 9]
            video.embed_code  = "<embed src=\"http://www.veoh.com/videodetails2.swf?permalinkId=#{id}&id=anonymous&player=videodetailsembedded&videoAutoPlay=0\" allowFullScreen=\"true\" width=\"540\" height=\"438\" bgcolor=\"#000000\" type=\"application/x-shockwave-flash\" pluginspage=\"http://www.macromedia.com/go/getflashplayer\"></embed><br/><a href=\"http://www.veoh.com/\">Online Videos by Veoh.com</a>"
            video.swf_url     = "http://www.veoh.com/videodetails2.swf?permalinkId=#{id}&id=anonymous&player=videodetailsembedded&videoAutoPlay=0"
          end
        elsif url[/^(http|https):\/\/(.*)?livevideo\.com\//] # *.livevideo.com
         if !url.index('/video/').nil?
           url =  url[0, url.rindex('/')]
           if url[/\/video\/[\w-]+\/[\w-]+/]
             url = url[/\/video\/[\w-]+\/[\w-]+/][7, url[/\/video\/[\w-]+\/[\w-]+/].length - 7]
             id = url[url.index('/') + 1, url.length]
           else
             id = url[/\/video\/[\w-]+/][7, url[/\/video\/[\w-]+/].length - 7]
           end
           video.embed_code  = "<embed src=\"http://www.livevideo.com/flvplayer/embed/#{id}\" type=\"application/x-shockwave-flash\" quality=\"high\" WIDTH=\"445\" HEIGHT=\"369\" wmode=\"transparent\"></embed>"
           video.swf_url     = "http://www.livevideo.com/flvplayer/embed/#{id}"
         end
        elsif url[/^(http|https):\/\/(.*)?metacafe.com\//] # *.metacafe.com
          if !url.index('/watch/').nil?
            id = url[/\/watch\/\d+\/\w+/][7, url[/\/watch\/\d+\/\w+/].length]
            video.embed_code  = "<embed src=\"http://www.metacafe.com/fplayer/#{id}.swf\" width=\"400\" height=\"345\" wmode=\"transparent\" pluginspage=\"http://www.macromedia.com/go/getflashplayer\" type=\"application/x-shockwave-flash\"> </embed>"
            video.swf_url     = "http://www.metacafe.com/fplayer/#{id}.swf"
          end
        elsif url[/^(http|https):\/\/www\.msnbc\.msn\.com\/id\//] or url[/^(http|https):\/\/nbcsports\.msnbc\.com\/id\//] # www.msnbc.msn.com
          if !url.index('#').nil?
            id = url[/#\d+/][1, url[/#\d+/].length]
            video.embed_code = "<iframe class=\"gawkk-generated-embed-code\" height=\"339\" width=\"425\" src=\"http://www.msnbc.msn.com/id/22425001/vp/#{id}##{id}\" frameborder=\"0\" scrolling=\"no\"></iframe>"
          end
        elsif url[/^(http|https):\/\/(.*)?fancast.com\/(.*)?\/videos$/]
          video.embed_code = "<iframe src=\"#{url[0, url.length - 6]}embed\" width=\"420\" height=\"355\" scrolling=\"no\" frameborder=\"0\"></iframe>"
        elsif url[/^(http|https):\/\/sports\.espn\.go\.com\//]
          if !url.index('videoId').nil?
            id = url[/videoId=\d+/][8, url[/videoId=\d+/].length]
            video.embed_code  = "<object width=\"440\" height=\"361\"><param name=\"movie\" value=\"http://sports.espn.go.com/broadband/player.swf?mediaId=#{id}\"/><param name=\"wmode\" value=\"transparent\"/><param name=\"allowScriptAccess\" value=\"always\"/><embed src=\"http://sports.espn.go.com/broadband/player.swf?mediaId=#{id}\" type=\"application/x-shockwave-flash\" wmode=\"transparent\" width=\"440\" height=\"361\" allowScriptAccess=\"always\"></embed></object>"
          end
        elsif url[/^(http|https):\/\/(.*)?mtvmusic\.com\//]
          if !url.index('id').nil?
            id = url[/id=\d+/][3, url[/id=\d+/].length]
            video.embed_code  = "<embed src=\"http://media.mtvnservices.com/mgid:uma:video:mtvmusic.com:#{id}\" width=\"320\" height=\"271\" type=\"application/x-shockwave-flash\" flashVars=\"dist=http://www.mtvmusic.com\" allowFullScreen=\"true\" AllowScriptAccess=\"never\"></embed>"
          end
        elsif url[/^(http|https):\/\/(.*)?joost\.com\//]
          video_id = url[url.index('joost.com/') + 10, url.length]
          video.embed_code = "<object width=\"640\" height=\"360\"><param name=\"movie\" value=\"http://www.joost.com/embed/#{video_id}\"></param><param name=\"allowFullScreen\" value=\"true\"></param><param name=\"allowNetworking\" value=\"all\"></param><param name=\"allowScriptAccess\" value=\"always\"></param><embed src=\"http://www.joost.com/embed/#{video_id}\" type=\"application/x-shockwave-flash\" allowfullscreen=\"true\" allowscriptaccess=\"always\" allownetworking=\"all\" width=\"640\" height=\"360\"></embed></object>"
        elsif url[/^(http|https):\/\/feeds\.wsjonline\.com\//]
          if !url.index('.html').nil?
            video_id = url[url.rindex('/') + 1, url.index('.html') - url.rindex('/') - 1]
            video.embed_code = "<embed src=\"http://s.wsj.net/media/swf/main.swf\" bgcolor=\"#FFFFFF\" flashVars=\"videoGUID={#{video_id}}&playerid=1000&configURL=http://wsj.vo.llnwd.net/o28/players/&autoStart=false” base=\"http://s.wsj.net/media/swf/\" name=\"flashPlayer\" width=\"512\" height=\"363\" seamlesstabbing=\"false\" type=\"application/x-shockwave-flash\" swLiveConnect=\"true\" pluginspage=\"http://www.macromedia.com/shockwave/download/index.cgi?P1_Prod_Version=ShockwaveFlash\"></embed>"
          end
        elsif url[/^(http|https):\/\/(.*)?thedailyshow\.com\//]
          if !url.index('videoId').nil?
            video_id = url[/videoId=\d+/][8, url[/videoId=\d+/].length]
            video.embed_code = "<embed src=\"http://media.mtvnservices.com/mgid:cms:item:comedycentral.com:#{video_id}\" width=\"360\" height=\"301\" type=\"application/x-shockwave-flash\" wmode=\"window\" allowFullscreen=\"true\" allowscriptaccess=\"always\" allownetworking=\"all\" flashvars=\"autoPlay=false\" bgcolor=\"#000000\"></embed>"
          end
        end
      rescue
        video.embed_code = ''
        video.swf_url = ''
      end
    end
    
    video.embed_code
  end
  
  def self.scrub(embed_code, center = false)
    if !embed_code.blank? and embed_code == embed_code[URI.regexp]
      embed_code = ''
    elsif center and embed_code[/^<center>/].nil?
      embed_code = '<center>' + embed_code + '</center>'
    end
    
    embed_code
  end
end