#********************************************************************************
#Copyright 2009 Octazen Solutions
#All Rights Reserved
#
#You may not reprint or redistribute this code without permission from Octazen Solutions.
#
#WWW: http://www.octazen.com
#Email: support@octazen.com
#********************************************************************************

module Octazen
  
  class AolImporter < WebRequestor
	
    def initialize()
      super()
    end
		
    def fetch_contacts (loginemail, password)

      loginid = login_id(loginemail)
      domain = domain(loginemail)
      #loginemail =~ /\s*(.*?)@(.*)\s*/
      #loginid = $1
      #domain = $2

      @domain = domain
      login = loginemail
      loginurl = nil
      if domain=='aol.in'
        loginurl = 'http://webmail.aol.in';
      elsif domain=='aol.de'
        login = loginid
        loginurl = 'http://webmail.aol.de';
      elsif domain=='aol.com' || domain=='aim.com' ||domain=='aol.co.uk'
        login = loginid
        loginurl = 'http://webmail.aol.com';
      else
        #login = loginid
        loginurl = 'http://webmail.aol.com';
      end
      
      #Get login form
      html = http_get(loginurl)
      form = HtmlFormParser.extract_form_by_name(html,'AOLLoginForm')
      raise UnexpectedFormatError, 'Cannot find login form' if form.nil?
      form.set_field('loginId',login);
      form.set_field('password',password);
      form.set_field("_authtrkcde", "{#TRKCDE#}");
      html = post_form(form)
      raise UserInputRequiredError, 'AOL requires you to answer some security questions' if html.include? 'Account Security Question'
      raise AuthenticationError, 'Bad user name or password' if html.include?('Invalid Screen Name or Password') || html.include?('snsmPRDetailErr')

      #Get redirection
      if html =~ /<body onLoad="checkErrorAndSubmitForm.*?'(http.*?)'.*>/im
        #mechanize has a bug where the last %3D%3D is reduced to a single %3D. We append an ampersand to work around this
        location = $1+"&"
        html = http_get(location)
        raise UserInputRequiredError, 'AOL requires you to answer some security questions' if html.include?('Account Security Question')
      end

      #New AOL adds 2nd level redirection
      if html =~ /<body onLoad="checkErrorAndSubmitForm.*?'(http.*?)'.*>/im
        #mechanize has a bug where the last %3D%3D is reduced to a single %3D. We append an ampersand to work around this
        location = $1+"&"
        html = http_get(location)
        raise UserInputRequiredError, 'AOL requires you to answer some security questions' if html.include?('Account Security Question')
      end
	  
      #Get host for webmail
      if html =~ /var gPreferredHost = "?([^";]*).*?var gTargetHost = "?([^";]*).*?var gSuccessPath = "?([^";]*)/im
        preferredhost = $1
        targethost = $2
        successpath = $3
        if targethost!="null"
          preferredhost = targethost
        end
        @homeuri = "http://"+preferredhost+successpath
      else 
        raise UnexpectedFormatError, 'Cannot find preferred host name and path'
      end

      location = URI.join(@homeuri,'Lite/PeoplePicker.aspx?type=compose')
      html = http_get(location)
      regex = /(?:<span class="contactSelectName">([^<]*)<\/span>\s*)?<span class="contactSelectEmail">([^<]*)<\/span>/im			
      al = []
      html.scan(regex) {
        email = HtmlTools.decode_html($2)
        name = nil
        if ($1.nil? == false)
          name = HtmlTools.decode_html($1)
        end
        if !email.nil?
          if email.index('@').nil?
            email = email+"@"+domain;
          end
          al.push(Contact.new(name,email))
        end
      }
      al
    end
  end
  
  # AOL
#  DOMAIN_IMPORTERS['aol2']='AolImporter2'
 DOMAIN_IMPORTERS['aol']=AolImporter
  DOMAIN_IMPORTERS['aol.com']=AolImporter
  DOMAIN_IMPORTERS['aim.com']=AolImporter
  DOMAIN_IMPORTERS['netscape.net']=AolImporter
  DOMAIN_IMPORTERS['aol.in']=AolImporter
  DOMAIN_IMPORTERS['aol.co.uk']=AolImporter
  DOMAIN_IMPORTERS['aol.com.br']=AolImporter
  DOMAIN_IMPORTERS['aol.de']=AolImporter
  DOMAIN_IMPORTERS['aol.fr']=AolImporter
  DOMAIN_IMPORTERS['aol.nl']=AolImporter
  DOMAIN_IMPORTERS['aol.se']=AolImporter
  DOMAIN_IMPORTERS['aol.es']=AolImporter
  DOMAIN_IMPORTERS['aol.it']=AolImporter
  DOMAIN_IMPORTERS['bestcoolcars.com']=AolImporter
  DOMAIN_IMPORTERS['car-nut.net']=AolImporter
  DOMAIN_IMPORTERS['crazycarfan.com']=AolImporter
  DOMAIN_IMPORTERS['in2autos.net']=AolImporter
  DOMAIN_IMPORTERS['intomotors.com']=AolImporter
  DOMAIN_IMPORTERS['motor-nut.com']=AolImporter
  DOMAIN_IMPORTERS['asylum.com']=AolImporter
  DOMAIN_IMPORTERS['blackvoices.com']=AolImporter
  DOMAIN_IMPORTERS['focusedonprofits.com']=AolImporter
  DOMAIN_IMPORTERS['focusedonreturns.com']=AolImporter
  DOMAIN_IMPORTERS['ilike2invest.com']=AolImporter
  DOMAIN_IMPORTERS['interestedinthejob.com']=AolImporter
  DOMAIN_IMPORTERS['netbusiness.com']=AolImporter
  DOMAIN_IMPORTERS['right4thejob.com']=AolImporter
  DOMAIN_IMPORTERS['alwayswatchingmovies.com']=AolImporter
  DOMAIN_IMPORTERS['alwayswatchingtv.com']=AolImporter
  DOMAIN_IMPORTERS['beabookworm.com']=AolImporter
  DOMAIN_IMPORTERS['bigtimereader.com']=AolImporter
  DOMAIN_IMPORTERS['chat-with-me.com']=AolImporter
  DOMAIN_IMPORTERS['crazyaboutfilms.net']=AolImporter
  DOMAIN_IMPORTERS['crazymoviefan.com']=AolImporter
  DOMAIN_IMPORTERS['fanofbooks.com']=AolImporter
  DOMAIN_IMPORTERS['games.com']=AolImporter
  DOMAIN_IMPORTERS['getintobooks.com']=AolImporter
  DOMAIN_IMPORTERS['i-dig-movies.com']=AolImporter
  DOMAIN_IMPORTERS['idigvideos.com']=AolImporter
  DOMAIN_IMPORTERS['iwatchrealitytv.com']=AolImporter
  DOMAIN_IMPORTERS['moviefan.com']=AolImporter
  DOMAIN_IMPORTERS['news-fanatic.com']=AolImporter
  DOMAIN_IMPORTERS['newspaperfan.com']=AolImporter
  DOMAIN_IMPORTERS['onlinevideosrock.com']=AolImporter
  DOMAIN_IMPORTERS['realitytvaddict.net']=AolImporter
  DOMAIN_IMPORTERS['realitytvnut.com']=AolImporter
  DOMAIN_IMPORTERS['reallyintomusic.com']=AolImporter
  DOMAIN_IMPORTERS['thegamefanatic.com']=AolImporter
  DOMAIN_IMPORTERS['totallyintomusic.com']=AolImporter
  DOMAIN_IMPORTERS['totallyintoreading.com']=AolImporter
  DOMAIN_IMPORTERS['totalmoviefan.com']=AolImporter
  DOMAIN_IMPORTERS['tvchannelsurfer.com']=AolImporter
  DOMAIN_IMPORTERS['videogamesrock.com']=AolImporter
  DOMAIN_IMPORTERS['wild4music.com']=AolImporter
  DOMAIN_IMPORTERS['alwaysgrilling.com']=AolImporter
  DOMAIN_IMPORTERS['alwaysinthekitchen.com']=AolImporter
  DOMAIN_IMPORTERS['besure2vote.com']=AolImporter
  DOMAIN_IMPORTERS['cheatasrule.com']=AolImporter
  DOMAIN_IMPORTERS['crazy4homeimprovement.com']=AolImporter
  DOMAIN_IMPORTERS['descriptivemail.com']=AolImporter
  DOMAIN_IMPORTERS['differentmail.com']=AolImporter
  DOMAIN_IMPORTERS['easydoesit.com']=AolImporter
  DOMAIN_IMPORTERS['expertrenovator.com']=AolImporter
  DOMAIN_IMPORTERS['expressivemail.com']=AolImporter
  DOMAIN_IMPORTERS['fanofcooking.com']=AolImporter
  DOMAIN_IMPORTERS['fieldmail.com']=AolImporter
  DOMAIN_IMPORTERS['fleetmail.com']=AolImporter
  DOMAIN_IMPORTERS['funkidsemail.com']=AolImporter
  DOMAIN_IMPORTERS['getfanbrand.com']=AolImporter
  DOMAIN_IMPORTERS['i-love-restaurants.com']=AolImporter
  DOMAIN_IMPORTERS['ilike2helpothers.com']=AolImporter
  DOMAIN_IMPORTERS['ilovehomeprojects.com']=AolImporter
  DOMAIN_IMPORTERS['lovefantasysports.com']=AolImporter
  DOMAIN_IMPORTERS['luckymail.com']=AolImporter
  DOMAIN_IMPORTERS['mail2me.com']=AolImporter
  DOMAIN_IMPORTERS['mail4me.com']=AolImporter
  DOMAIN_IMPORTERS['majorshopaholic.com']=AolImporter
  DOMAIN_IMPORTERS['realbookfan.com']=AolImporter
  DOMAIN_IMPORTERS['scoutmail.com']=AolImporter
  DOMAIN_IMPORTERS['thefanbrand.com']=AolImporter
  DOMAIN_IMPORTERS['totally-into-cooking.com']=AolImporter
  DOMAIN_IMPORTERS['totallyintocooking.com']=AolImporter
  DOMAIN_IMPORTERS['volunteeringisawesome.com']=AolImporter
  DOMAIN_IMPORTERS['voluteer4fun.com']=AolImporter
  DOMAIN_IMPORTERS['wayintocomputers.com']=AolImporter
  DOMAIN_IMPORTERS['whatmail.com']=AolImporter
  DOMAIN_IMPORTERS['when.com']=AolImporter
  DOMAIN_IMPORTERS['wildaboutelectronics.com']=AolImporter
  DOMAIN_IMPORTERS['workingaroundthehouse.com']=AolImporter
  DOMAIN_IMPORTERS['workingonthehouse.com']=AolImporter
  DOMAIN_IMPORTERS['writesoon.com']=AolImporter
  DOMAIN_IMPORTERS['xmasmail.com']=AolImporter
  DOMAIN_IMPORTERS['beahealthnut.com']=AolImporter
  DOMAIN_IMPORTERS['ilike2workout.com']=AolImporter
  DOMAIN_IMPORTERS['ilikeworkingout.com']=AolImporter
  DOMAIN_IMPORTERS['iloveworkingout.com']=AolImporter
  DOMAIN_IMPORTERS['love2exercise.com']=AolImporter
  DOMAIN_IMPORTERS['love2workout.com']=AolImporter
  DOMAIN_IMPORTERS['lovetoexercise.com']=AolImporter
  DOMAIN_IMPORTERS['realhealthnut.com']=AolImporter
  DOMAIN_IMPORTERS['totalfoodnut.com']=AolImporter
  DOMAIN_IMPORTERS['acatperson.com']=AolImporter
  DOMAIN_IMPORTERS['adogperson.com']=AolImporter
  DOMAIN_IMPORTERS['bigtimecatperson.com']=AolImporter
  DOMAIN_IMPORTERS['bigtimedogperson.com']=AolImporter
  DOMAIN_IMPORTERS['cat-person.com']=AolImporter
  DOMAIN_IMPORTERS['catpeoplerule.com']=AolImporter
  DOMAIN_IMPORTERS['dog-person.com']=AolImporter
  DOMAIN_IMPORTERS['dogpeoplerule.com']=AolImporter
  DOMAIN_IMPORTERS['mycatiscool.com']=AolImporter
  DOMAIN_IMPORTERS['fanofcomputers.com']=AolImporter
  DOMAIN_IMPORTERS['fanoftheweb.com']=AolImporter
  DOMAIN_IMPORTERS['idigcomputers.com']=AolImporter
  DOMAIN_IMPORTERS['idigelectronics.com']=AolImporter
  DOMAIN_IMPORTERS['ilikeelectronics.com']=AolImporter
  DOMAIN_IMPORTERS['majortechie.com']=AolImporter
  DOMAIN_IMPORTERS['switched.com']=AolImporter
  DOMAIN_IMPORTERS['total-techie.com']=AolImporter
  DOMAIN_IMPORTERS['allsportsrock.com']=AolImporter
  DOMAIN_IMPORTERS['basketball-email.com']=AolImporter
  DOMAIN_IMPORTERS['beagolfer.com']=AolImporter
  DOMAIN_IMPORTERS['bigtimesportsfan.com']=AolImporter
  DOMAIN_IMPORTERS['crazy4baseball.com']=AolImporter
  DOMAIN_IMPORTERS['futboladdict.com']=AolImporter
  DOMAIN_IMPORTERS['hail2theskins.com']=AolImporter
  DOMAIN_IMPORTERS['hitthepuck.com']=AolImporter
  DOMAIN_IMPORTERS['iloveourteam.com']=AolImporter
  DOMAIN_IMPORTERS['luvfishing.com']=AolImporter
  DOMAIN_IMPORTERS['luvgolfing.com']=AolImporter
  DOMAIN_IMPORTERS['luvsoccer.com']=AolImporter
  DOMAIN_IMPORTERS['majorgolfer.com']=AolImporter
  DOMAIN_IMPORTERS['myfantasyteamrocks.com']=AolImporter
  DOMAIN_IMPORTERS['myfantasyteamrules.com']=AolImporter
  DOMAIN_IMPORTERS['myteamisbest.com']=AolImporter
  DOMAIN_IMPORTERS['redskinsfancentral.com']=AolImporter
  DOMAIN_IMPORTERS['redskinsultimatefan.com']=AolImporter
  DOMAIN_IMPORTERS['skins4life.com']=AolImporter
  DOMAIN_IMPORTERS['totallyintobaseball.com']=AolImporter
  DOMAIN_IMPORTERS['totallyintobasketball.com']=AolImporter
  DOMAIN_IMPORTERS['totallyintofootball.com']=AolImporter
  DOMAIN_IMPORTERS['totallyintogolf.com']=AolImporter
  DOMAIN_IMPORTERS['totallyintohockey.com']=AolImporter
  DOMAIN_IMPORTERS['totallyintosports.com']=AolImporter
  DOMAIN_IMPORTERS['ultimateredskinsfan.com']=AolImporter
  DOMAIN_IMPORTERS['realtravelfan.com']=AolImporter
  DOMAIN_IMPORTERS['totallyintotravel.com']=AolImporter
  DOMAIN_IMPORTERS['travel2newplaces.com']=AolImporter
  DOMAIN_IMPORTERS['icqmail.com']=AolImporter
  DOMAIN_IMPORTERS['1ramsfan.com']=AolImporter
  DOMAIN_IMPORTERS['all4rams.com']=AolImporter
  DOMAIN_IMPORTERS['all4theskins.com']=AolImporter
  DOMAIN_IMPORTERS['angeliamail.com']=AolImporter
  DOMAIN_IMPORTERS['backheel.net']=AolImporter
  DOMAIN_IMPORTERS['believeinliberty.com']=AolImporter
  DOMAIN_IMPORTERS['bestjobcandidate.com']=AolImporter
  DOMAIN_IMPORTERS['capsfanatic.com']=AolImporter
  DOMAIN_IMPORTERS['capshockeyfan.com']=AolImporter
  DOMAIN_IMPORTERS['capsred.com']=AolImporter
  DOMAIN_IMPORTERS['compuserve.com']=AolImporter
  DOMAIN_IMPORTERS['crazy4mail.com']=AolImporter
  DOMAIN_IMPORTERS['crazyforemail.com']=AolImporter
  DOMAIN_IMPORTERS['fanaticos.com']=AolImporter
  DOMAIN_IMPORTERS['glad2bglbt.com']=AolImporter
  DOMAIN_IMPORTERS['halocovenants.net']=AolImporter
  DOMAIN_IMPORTERS['lemondrop.com']=AolImporter
  DOMAIN_IMPORTERS['makemailperfect.com']=AolImporter
  DOMAIN_IMPORTERS['mcom.com']=AolImporter
  DOMAIN_IMPORTERS['mycapitalsmail.com']=AolImporter
  DOMAIN_IMPORTERS['noisecreep.com']=AolImporter
  DOMAIN_IMPORTERS['politicsdaily.com']=AolImporter
  DOMAIN_IMPORTERS['ramsbringit.com']=AolImporter
  DOMAIN_IMPORTERS['ramsforlife.com']=AolImporter
  DOMAIN_IMPORTERS['ramsmail.com']=AolImporter
  DOMAIN_IMPORTERS['redskinscheer.com']=AolImporter
  DOMAIN_IMPORTERS['redskinsfamily.com']=AolImporter
  DOMAIN_IMPORTERS['redskinshog.com']=AolImporter
  DOMAIN_IMPORTERS['redskinsrule.com']=AolImporter
  DOMAIN_IMPORTERS['redskinsspecialteams.com']=AolImporter
  DOMAIN_IMPORTERS['stargate2.com']=AolImporter
  DOMAIN_IMPORTERS['stargateatlantis.com']=AolImporter
  DOMAIN_IMPORTERS['stargatefanclub.com']=AolImporter
  DOMAIN_IMPORTERS['stargatesg1.com']=AolImporter
  DOMAIN_IMPORTERS['stargateu.com']=AolImporter
  DOMAIN_IMPORTERS['urlesque.com']=AolImporter

end

