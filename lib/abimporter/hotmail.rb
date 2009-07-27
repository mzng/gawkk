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

  class HotmailImporter < WebRequestor
	
    def initialize()
      super()
    end
    
    def fetch_contacts (loginemail, password)

	  password=password[0,16] if password.length>16

      #Hotmail mobile no longer allows session sharing with hotmail live
      # form = Octazen::HttpForm.new
      # form.add_field('__EVENTTARGET', '.')
      # form.add_field('__EVENTARGUMENT', '')
      # form.add_field('LoginTextBox', loginemail)
      # form.add_field('DomainField', 'passport.com')
      # form.add_field('PasswordTextBox', password)
      # form.add_field('PasswordSubmit', 'Sign in')
      # form.action = 'https://mid.live.com/si/post.aspx?lc=1033&id=71570&ru=http%3a%2f%2fmobile.live.com%2fwml%2fmigrate.aspx%3freturl%3dhttp%253a%252f%252fmobile.live.com%252fhm%252fDefault.aspx%26fti%3dy&mlc=en-US&mspsty=302&mspto=1&tw=14400&kv=2'
      # html = post_form(form)
      
      # if last_url.include?('error.asp') || html.include?('AllAnnotations_Error')
        # raise AuthenticationError, 'Bad user name or password'
      # end
      html = http_get('https://login.live.com/ppsecure/post.srf?id=2&svc=mail')
      form = HtmlFormParser.extract_form_by_name(html,'f1')
      raise UnexpectedFormatError, 'Cannot find login form' if form.nil?
      form.set_field('login',loginemail);
      form.set_field('passwd',password);
      form.set_field("_authtrkcde", "{#TRKCDE#}");
      html = post_form(form)
      raise AuthenticationError, 'Bad user name or password' if  \
      html.include?('The e-mail address or password is incorrect')  \
        || html.include?('The password is incorrect') \
        || html.include?('Please type your e-mail address in the following format') \
        || html.include?('The .NET Passport or Windows Live ID you are signed into is not supported') \
        || html.include?('alt="Error symbol"') \
        || html.include?('srf_fError=1') 
      #html =~ /window.location.replace\("([^"]*)"\)/i
      #raise UnexpectedFormatError, 'Cannot find redirect location' if $1.nil?
      #location = $1
      #html = http_get(location)
      html = http_get('http://mail.live.com')

      html =~ /<iframe\s+id="UIFrame".*?src="([^"]*)/i
	  unless $1.nil?
        url = HtmlTools.decode_html($1)
		html = http_get(url)
	  end
	  
	  #New hotmail interstitials for some accounts
      form = HtmlFormParser.extract_form_by_name(html,'MessageAtLoginForm')
	  if !form.nil?
		form.set_field('TakeMeToInbox','continue')
		html = post_form(form)
	  end
      
      #html = http_get('/mail/ContactPickerLight.aspx?n='+rand(100000).to_s)
      html = http_get('http://mail.live.com/mail/ContactPickerLight.aspx?n='+rand(100000).to_s)

	  html =~ /<iframe\s+id="UIFrame".*?src="([^"]*)/i
	  unless $1.nil?
        url = HtmlTools.decode_html($1)
		html = http_get(url)
	  end

      regex = /<tr>.*?<td class="dContactPickerBodyNameCol">.*?&#x200.;\s*(.*?)\s*&#x200.;.*?<\/td>\s*<td class="dContactPickerBodyEmailCol">\s*([^<]*?)\s*<\/td>.*?<\/tr>/im
      al = []
      html.scan(regex) {
        name = HtmlTools.decode_html($1)
        email = HtmlTools.decode_html($2)
        if !email.nil?
          al.push(Contact.new(name,email))
        end
      }
      al
    end
  end

  #Hotmail
  DOMAIN_IMPORTERS['hotmail.com']=HotmailImporter
  DOMAIN_IMPORTERS['msn.com']=HotmailImporter
  DOMAIN_IMPORTERS['hotmail.fr']=HotmailImporter
  DOMAIN_IMPORTERS['hotmail.it']=HotmailImporter
  DOMAIN_IMPORTERS['hotmail.de']=HotmailImporter
  DOMAIN_IMPORTERS['hotmail.co.jp']=HotmailImporter
  DOMAIN_IMPORTERS['hotmail.co.uk']=HotmailImporter
  DOMAIN_IMPORTERS['hotmail.com.ar']=HotmailImporter
  DOMAIN_IMPORTERS['hotmail.co.th']=HotmailImporter
  DOMAIN_IMPORTERS['hotmail.com.tr']=HotmailImporter
  DOMAIN_IMPORTERS['hotmail.es']=HotmailImporter
  DOMAIN_IMPORTERS['msnhotmail.com']=HotmailImporter
  DOMAIN_IMPORTERS['hotmail.jp']=HotmailImporter
  DOMAIN_IMPORTERS['hotmail.se']=HotmailImporter
  DOMAIN_IMPORTERS['hotmail.com.br']=HotmailImporter
  DOMAIN_IMPORTERS['live.com.ar']=HotmailImporter
  DOMAIN_IMPORTERS['live.com.au']=HotmailImporter
  DOMAIN_IMPORTERS['live.at']=HotmailImporter
  DOMAIN_IMPORTERS['live.be']=HotmailImporter
  DOMAIN_IMPORTERS['live.ca']=HotmailImporter
  DOMAIN_IMPORTERS['live.cl']=HotmailImporter
  DOMAIN_IMPORTERS['live.cn']=HotmailImporter
  DOMAIN_IMPORTERS['live.dk']=HotmailImporter
  DOMAIN_IMPORTERS['live.fr']=HotmailImporter
  DOMAIN_IMPORTERS['live.de']=HotmailImporter
  DOMAIN_IMPORTERS['live.hk']=HotmailImporter
  DOMAIN_IMPORTERS['live.ie']=HotmailImporter
  DOMAIN_IMPORTERS['live.it']=HotmailImporter
  DOMAIN_IMPORTERS['live.jp']=HotmailImporter
  DOMAIN_IMPORTERS['live.co.kr']=HotmailImporter
  DOMAIN_IMPORTERS['live.com.my']=HotmailImporter
  DOMAIN_IMPORTERS['live.com.mx']=HotmailImporter
  DOMAIN_IMPORTERS['live.nl']=HotmailImporter
  DOMAIN_IMPORTERS['live.no']=HotmailImporter
  DOMAIN_IMPORTERS['live.ru']=HotmailImporter
  DOMAIN_IMPORTERS['live.com.sg']=HotmailImporter
  DOMAIN_IMPORTERS['live.co.za']=HotmailImporter
  DOMAIN_IMPORTERS['live.se']=HotmailImporter
  DOMAIN_IMPORTERS['live.co.uk']=HotmailImporter
  DOMAIN_IMPORTERS['live.com']=HotmailImporter
  DOMAIN_IMPORTERS['windowslive.com']=HotmailImporter
  
end

