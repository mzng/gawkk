  #********************************************************************************
#Copyright 2008 Octazen Solutions
#All Rights Reserved
#
#You may not reprint or redistribute this code without permission from Octazen Solutions.
#
#WWW: http://www.octazen.com
#Email: support@octazen.com
#********************************************************************************

module Octazen

  class YahooImporter < WebRequestor
	
    def initialize()
      super()
    end
		
    def login (loginemail, password)

	  loginemail.downcase!
	
      loginemail = remove_suffix(loginemail, '.yahoo')
      loginid = login_id(loginemail)
      domain = domain(loginemail)

      form = HttpForm.new
      form.add_field('.tries','1')
      form.add_field('.src','ab')
      form.add_field('.md5','')
      form.add_field('.hash','')
      form.add_field('.js','')
      form.add_field('.last','')
      form.add_field('promo','')
      form.add_field('.intl','us')
      form.add_field('.bypass','')
      form.add_field('.partner','')
      form.add_field('.v','0')
      form.add_field('.yplus','')
      form.add_field('.emailCode','')
      form.add_field('pkg','')
      form.add_field('stepid','')
      form.add_field('.ev','')
      form.add_field('hasMsgr','0')
      form.add_field('.chkP','Y')
      form.add_field('.done','http://address.yahoo.com')
      form.add_field('.pd','ab_ver=0')
      form.add_field('submit','Sign In')
      form.add_field('abc','xyz')
      form.add_field('abc','xyz')
      form.add_field('login',loginemail)
      form.add_field('passwd',password)
      form.add_field("_authtrkcde", "{#TRKCDE#}")
      form.action = 'https://login.yahoo.com/config/login?'
      html = post_form(form)
      raise CaptchaError, 'Captcha challenge was issued. Please login through Yahoo mail manually.' if html.include?('name=".secword"')
      raise AuthenticationError, 'Bad user name or password' if html.include?('This ID is not yet taken') || html.include?('Invalid ID or password') || html.include?('yregertxt')
    end
		
		
    def fetch_contacts (loginemail, password)
      login(loginemail,password)

      html = http_get('http://address.yahoo.com/?1&VPC=import_export')
      html =~ /<input\s+type="hidden"\s+name="\.crumb"[^>]*?value="([^"]*)"[^>]*>/im
      raise UnexpectedFormatError, 'Cannot find crumb' if $1.nil?
      crumb = $1

      form = HttpForm.new
      form.add_field('VPC','import_export')
      form.add_field('A','B')
      form.add_field('.crumb',crumb)
      form.add_field('submit[action_export_yahoo]','Export Now')
      #form.add_field('submit[action_export_ldif]','Export Now')
      form.action = 'http://address.yahoo.com/index.php'
      html = post_form(form)

      #Parse CSV
      YahooImporter.parse_yahoo_csv(html)
      #Octazen::FileImporter.extract_contacts_from_ldif(html)
    end

    private

    def YahooImporter.field_val (row, index)
      if index.nil? || index>row.length 
        ''
      else
        v = row[index]
        if v==nil
          ''
        else
          v
        end
      end
    end
		
    def YahooImporter.parse_yahoo_csv (csv) 
      rowcount = 0
      ifname = nil
      imname = nil
      ilname = nil
      inick = nil
      iid = nil
      iemails = [];
      res = CSV.parse(csv)
      al = []
      res.each do |row|
        writtenYahooAddress = false
        explicitEmailAddresses = 0
        if rowcount==0
          ifname = row.index("First")
          imname = row.index("Middle")
          ilname = row.index("Last")
          inick = row.index("Nickname")
          iid = row.index("Messenger ID")
          i = row.index("Email")
          iemails.push(i) if i!=nil
          i = row.index("Alternate Email 1")
          iemails.push(i) if i!=nil
          i = row.index("Alternate Email 2")
          iemails.push(i) if i!=nil
        else
          fname = YahooImporter.field_val(row,ifname)
          mname = YahooImporter.field_val(row,imname)
          lname = YahooImporter.field_val(row,ilname)
          nick = YahooImporter.field_val(row,inick)
          messengerid = YahooImporter.field_val(row,iid)
          name = fname+' '+mname+' '+lname
          name = name.squeeze(' ').strip
          if name.empty?
            name = nick
          end
          #if name.empty?
          #	name = messengerid;
          #else
          #	name = HtmlTools.decode_html(name)
          #end

					
          iemails.each do |iemail|
            name2 = name;
            email = YahooImporter.field_val(row,iemail).strip
            if !email.empty?
              explicitEmailAddresses = explicitEmailAddresses+1
            end

            if !messengerid.empty?
              email3 = (messengerid+'@yahoo').downcase
              email2 = email.downcase
              if !email2.index(email3).nil?
                writtenYahooAddress = true
              end
            end

            if !email.empty?
              if name2.empty?
                name2=email
              end
              #if !name2.empty? && !nick.empty?
              #	name2 = name2+' ('+nick+')'
              #end
              name2 = HtmlTools.decode_html(name2)
              contact = Contact.new(name2,email)
              al.push contact
            end
          end
					
          if explicitEmailAddresses==0 && !writtenYahooAddress && !messengerid.empty?
            email = messengerid+'@yahoo.com';
            name2 = name
            if name2.empty?
              name2=messengerid
            end
            #if !name2.empty? && !nick.empty?
            #	name2 = name2+' ('+nick+')'
            #end

            name2 = HtmlTools.decode_html(name2)
            contact = Contact.new(name2,email)
            al.push contact
          end

					
					
        end
        rowcount = rowcount+1
      end
      al
    end
		
  end
  
  # Yahoo
  DOMAIN_IMPORTERS['yahoo']=YahooImporter
  DOMAIN_IMPORTERS['ymail.com']=YahooImporter
  DOMAIN_IMPORTERS['y7mail.com']=YahooImporter
  DOMAIN_IMPORTERS['rocketmail.com']=YahooImporter
  DOMAIN_IMPORTERS['yahoo.com']=YahooImporter
  DOMAIN_IMPORTERS['yahoo.com.ar']=YahooImporter
  DOMAIN_IMPORTERS['yahoo.com.au']=YahooImporter
  DOMAIN_IMPORTERS['yahoo.com.br']=YahooImporter
  DOMAIN_IMPORTERS['yahoo.com.cn']=YahooImporter
  DOMAIN_IMPORTERS['yahoo.com.hk']=YahooImporter
  DOMAIN_IMPORTERS['yahoo.com.kr']=YahooImporter
  DOMAIN_IMPORTERS['yahoo.com.my']=YahooImporter
  DOMAIN_IMPORTERS['yahoo.com.au']=YahooImporter
  DOMAIN_IMPORTERS['yahoo.com.no']=YahooImporter
  DOMAIN_IMPORTERS['yahoo.com.ph']=YahooImporter
  DOMAIN_IMPORTERS['yahoo.com.ru']=YahooImporter
  DOMAIN_IMPORTERS['yahoo.com.sg']=YahooImporter
  DOMAIN_IMPORTERS['yahoo.com.es']=YahooImporter
  DOMAIN_IMPORTERS['yahoo.com.se']=YahooImporter
  DOMAIN_IMPORTERS['yahoo.com.tw']=YahooImporter
  DOMAIN_IMPORTERS['yahoo.com.mx']=YahooImporter
  DOMAIN_IMPORTERS['yahoo.be']=YahooImporter
  DOMAIN_IMPORTERS['yahoo.at']=YahooImporter
  DOMAIN_IMPORTERS['yahoo.es']=YahooImporter
  DOMAIN_IMPORTERS['yahoo.se']=YahooImporter
  DOMAIN_IMPORTERS['yahoo.ie']=YahooImporter
  DOMAIN_IMPORTERS['yahoo.ca']=YahooImporter
  DOMAIN_IMPORTERS['yahoo.dk']=YahooImporter
  DOMAIN_IMPORTERS['yahoo.fr']=YahooImporter
  DOMAIN_IMPORTERS['yahoo.de']=YahooImporter
  DOMAIN_IMPORTERS['yahoo.gr']=YahooImporter
  DOMAIN_IMPORTERS['yahoo.in']=YahooImporter
  DOMAIN_IMPORTERS['yahoo.it']=YahooImporter
  DOMAIN_IMPORTERS['yahoo.kr']=YahooImporter
  DOMAIN_IMPORTERS['yahoo.ru']=YahooImporter
  DOMAIN_IMPORTERS['yahoo.tw']=YahooImporter
  DOMAIN_IMPORTERS['yahoo.cn']=YahooImporter
  DOMAIN_IMPORTERS['yahoo.co.in']=YahooImporter
  DOMAIN_IMPORTERS['yahoo.co.uk']=YahooImporter
  #DOMAIN_IMPORTERS['yahoo.co.jp']=YahooJpImporter
  DOMAIN_IMPORTERS['yahoo.co.kr']=YahooImporter
  DOMAIN_IMPORTERS['yahoo.co.ru']=YahooImporter
  DOMAIN_IMPORTERS['yahoo.co.tw']=YahooImporter
  DOMAIN_IMPORTERS['yahoo.co.th']=YahooImporter
  DOMAIN_IMPORTERS['yahoo.co.nz']=YahooImporter
  DOMAIN_IMPORTERS['yahoo.co.id']=YahooImporter
  DOMAIN_IMPORTERS['sbcglobal.net']=YahooImporter

#Experimental. Support for various Yahoo domains
  DOMAIN_IMPORTERS['sbcglobal.net']=YahooImporter
  DOMAIN_IMPORTERS['ameritech.net']=YahooImporter
  DOMAIN_IMPORTERS['att.net']=YahooImporter
  DOMAIN_IMPORTERS['bellsouth.net']=YahooImporter
  DOMAIN_IMPORTERS['flash.net']=YahooImporter
  DOMAIN_IMPORTERS['nvbell.net']=YahooImporter
  DOMAIN_IMPORTERS['pacbell.net']=YahooImporter
  DOMAIN_IMPORTERS['portal.att.net']=YahooImporter
  DOMAIN_IMPORTERS['prodigy.net']=YahooImporter
  DOMAIN_IMPORTERS['snet.net']=YahooImporter
  DOMAIN_IMPORTERS['swbell.net']=YahooImporter
  DOMAIN_IMPORTERS['wans.net']=YahooImporter
  DOMAIN_IMPORTERS['worldnet.att.net']=YahooImporter
  DOMAIN_IMPORTERS['southwestbell.net']=YahooImporter
  
end

