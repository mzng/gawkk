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

  #An older copy of the Gmail importer. Used as a backup in case Google contacts API fails with captcha exception
  class GmailImporterOld1 < WebRequestor
	
    def initialize()
      super()
    end
		
    def login (loginemail, password)

      loginemail = remove_suffix(loginemail,'.gmail')

	  domain = domain(loginemail).downcase
	  if domain=='gmail.com' || domain=='googlemail.com'
		@appDomain = nil
		@path = 'mail'
	  else
		@appDomain = domain
		@path = 'a/'+domain
	  end
	  
      #login = login_id(loginemail)
      location=''

      form = HttpForm.new
      form.add_field("ltmpl", "default");
      form.add_field("ltmplcache", "2");
      form.add_field("hl", "en");
      form.add_field("service", "mail");
      form.add_field("Passwd", password);
      form.add_field("rmShown", "1");
      form.add_field("null", "Sign in");
      form.add_field("_authtrkcde", "{#TRKCDE#}");
	  if @appDomain.nil?
		form.add_field("Email", loginemail);
		form.add_field("continue", "http://mail.google.com/mail?");
		form.action = 'https://www.google.com/accounts/ServiceLoginAuth'
	  else
		form.add_field("Email", login_id(loginemail));
		form.add_field("continue", 'https://mail.google.com/a/'+@appDomain+'/');
		form.add_field("rm", "false");
		form.add_field("asts", "");
		form.action = 'https://www.google.com/'+@path+'/LoginAction2?service=mail'
	  end
      html = post_form(form)
      raise AuthenticationError, 'Bad user name or password' if html.include?('Username and password do not match') || html.include?('class="errormsg"')
      raise CaptchaError, 'Captcha challenge raised by server' if html.include?('https://www.google.com/accounts/Captcha')
      raise UnsupportedAddressBookError, 'No Google Apps found for '+domain if html.include?('Server error')


      location = UrlTools.get_refresh_url(html)
	  unless location.nil?
		html = http_get(location)
	  end
      #raise UnexpectedFormatError, 'Cannot find redirection page' if location.nil?

      url2 = make_absolute(last_url,'/'+@path)
      ats = cookie_jar.get_cookie_values(url2, 'GMAIL_AT')
      at = ats[0] if !ats.nil? && ats.length>0
      if at.nil?
		#html = http_get('http://mail.google.com/mail/?view=sec')
        html = http_get('http://mail.google.com/'+@path+'/?view=sec')
        if html =~ /<input\s+type="hidden"\s+name="at"\s+value="([^"]+)"/ims
          at = HtmlTools.decode_html($1) 
        end
      end
      
      #Logged in
    end
		
		
		
    def fetch_contacts (loginemail, password)
      
      login(loginemail,password)
			
      #html = http_get('http://mail.google.com/mail/contacts/data/export?exportType=ALL&groupToExport=&out=GMAIL_CSV')
      #html = http_get('http://mail.google.com/mail/contacts/data/export?exportType=ALL&groupToExport=&out=OUTLOOK_CSV')

#      html = http_get('http://mail.google.com/'+@path+'/contacts/data/export?exportType=ALL&groupToExport=&out=OUTLOOK_CSV')

		limit =  Octazen::Config.get_config("gmail.limit_mycontacts", nil)
		if limit.nil?
			filter = Octazen::Config.get_config("gmail.filter", "all")
			limit=true if filter=='mycontacts'
		end

		if limit
			html = http_get('http://mail.google.com/'+@path+'/contacts/data/export?exportType=GROUP&groupToExport=%5EMine&out=OUTLOOK_CSV&lang=en&hl=en&l=en')
		else
			html = http_get('http://mail.google.com/'+@path+'/contacts/data/export?exportType=ALL&groupToExport=%5EMine&out=OUTLOOK_CSV&lang=en&hl=en&l=en')
		end


	
      #http://mail.google.com/mail/contacts/data/export?exportType=ALL&groupToExport=&out=GMAIL_CSV
      #http://mail.google.com/mail/contacts/data/export?exportType=ALL&groupToExport=&out=OUTLOOK_CSV
      GmailImporterOld1.parse_outlook_csv(html)
    end

    private

    def GmailImporterOld1.field_val (row, index)
      if index.nil? || index>row.length 
        ''
      else
        row[index]
      end
    end
		
    def GmailImporterOld1.parse_outlook_csv (csv)
      rowcount = 0
      iname = 5
      iemails = [13,14,15];
      res = CSV.parse(csv)
      al = []
      res.each do |row|

        if rowcount==0
          #Header ...skip for now
          #iname = row.index("Name")
          #i = row.index("E-mail Address")
          #iemails.push(i) if i!=nil
          #i = row.index("E-mail 2 Address")
          #iemails.push(i) if i!=nil
          #i = row.index("E-mail 3 Address")
          #iemails.push(i) if i!=nil
        else
          name = row[iname]

          if !name.nil?
            name = name.squeeze(' ').strip
          end
					
          iemails.each do |iemail|
            name2 = name;
            email = row[iemail]

            if !email.nil? && !email.empty?
              if name2.nil? || name2.empty?
                name2=email
              end
              contact = Contact.new(name2,email)
              al.push contact
            end
          end
        end
        rowcount = rowcount+1
      end
      al
    end
		
  end
	

  class GmailImporter < WebRequestor
	
    def initialize()
      @extra_headers = {}
      super()
    end
		
    def login (loginemail, password)

      #Disable errors from being raised for non 200 return codes
      @error_on_fail = false
      html = http_post('https://www.google.com/accounts/ClientLogin',  {'Email'=>loginemail, 'Passwd'=>password, 'service'=>'cp', 'source'=>'Octazen-ABI=1', 'accountType'=>'HOSTED_OR_GOOGLE'})
      if last_status_code==200
        #Success!
        html =~ /^Auth=(.*?)$/ims
        raise UnexpectedFormatError, 'Cannot find auth token' if $1.nil?
        @auth = $1
        @extra_headers['Authorization'] = 'GoogleLogin auth='+@auth
        @extra_headers['GData-Version'] = '2'
      elsif last_status_code==403
        #Error should be 403...
        html =~ /^Error=(.*?)$/ims
        raise UnexpectedFormatError, 'Cannot find error reason' if $1.nil?
        error = $1.strip
        if 'BadAuthentication'==error
          raise AuthenticationError, 'Bad user name or password'
        elsif 'NotVerified'==error
          raise AuthenticationError, 'Email address has not been verified'
        elsif 'TermsNotAgreed'==error
          raise AuthenticationError, 'Gmail terms not agreed'
        elsif 'CaptchaRequired'==error
          raise CaptchaError, 'Captcha challenge raised'
        elsif 'AccountDeleted'==error
          raise AuthenticationError, 'Account deleted'
        elsif 'AccountDisabled'==error
          raise AuthenticationError, 'Account disabled'
        elsif 'ServiceDisabled'==error
          raise AddressBookError, 'Service disabled'
        elsif 'ServiceUnavailable'==error
          raise AddressBookError, 'Google contacts service unavailable. Try again later.'
        else
          raise AddressBookError, 'Unknown gmail error'
        end
      else
        #Other errors
        raise UnexpectedFormatError, 'Unexpected error code '+last_status_code
      end
    end
		
		
    def fetch_contacts (loginemail, password)

#        obj = Octazen::GmailImporterOld1.new
#        return obj.fetch_contacts(loginemail,password)

      loginemail = remove_suffix(loginemail,'.gmail2')
      loginemail = remove_suffix(loginemail,'.gmail')
      
      begin
        login(loginemail,password)
      rescue Octazen::CaptchaError => err
        obj = Octazen::GmailImporterOld1.new
        return obj.fetch_contacts(loginemail,password)
      end
			
      url = "http://www.google.com/m8/feeds/contacts/default/full?max-results=10000";

			#Fetch from "My Contacts" only?
			
		limit =  Octazen::Config.get_config("gmail.limit_mycontacts", nil)
		if limit.nil?
			filter = Octazen::Config.get_config("gmail.filter", "all")
			limit=true if filter=='mycontacts'
		end
			
			if limit
	      html = http_request("http://www.google.com/m8/feeds/groups/default/full",'GET',nil,'iso-8859-1',@extra_headers)
				html.scan(/<entry.*?<id>([^<]*)<\/id>(.*?)<\/entry>/imsu) {
					gurl = $1
					gxml = $2
					if gxml =~ /<gContact:systemGroup\s+id='Contacts'/imsu
							url += "&group=" + CGI.escape(gurl);
							break;
					end
				}
			end


      html = http_request(url,'GET',nil,'iso-8859-1',@extra_headers)

      al = []
      html.scan(/<entry[^>]*>(.*?)<\/entry>/imsu) {
        entryHtml = $1
        name = nil
        entryHtml =~ /<title[^>]*>(.*?)<\/title>/imsu
        unless $1.nil?
          name = HtmlTools.decode_html($1)
        end

        al2 = []
        entryHtml.scan(/<gd:email[^>]*?.*?address='([^']*)'/imsu) {
          email = $1.strip
          #check if email is valid email address
          if email =~ /^([+=&'\/\\?\\^\\~a-zA-Z0-9\._-])+@([a-zA-Z0-9_-])+(\.[a-zA-Z0-9_-]+)+/
            al.push(Contact.new(name,email))
          end
        }
      }
      al
    end
    
    
  end
  

  # Gmail
  DOMAIN_IMPORTERS['gmail']=GmailImporter
  DOMAIN_IMPORTERS['gmail.com']=GmailImporter
  DOMAIN_IMPORTERS['googlemail.com']=GmailImporter
  DOMAIN_IMPORTERS['data.bg']=GmailImporter
  DOMAIN_IMPORTERS['mailbox.hu']=GmailImporter
  
end

