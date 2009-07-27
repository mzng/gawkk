#********************************************************************************
#Copyright 2009 Octazen Solutions
#All Rights Reserved
#
#You may not reprint or redistribute this code without permission from Octazen Solutions.
#
#WWW: http://www.octazen.com
#Email: support@octazen.com
#********************************************************************************

require 'rubygems'
require 'json'

module Octazen

  class LinkedInContact < Contact
    attr_reader :member_id
    attr_reader :uid
    def initialize (member_id,name,email)
      super(name,email)
      @member_id = member_id
      #uid is the same as member_id
      @uid = member_id
    end
  end
	
  class LinkedInImporter < WebRequestor
    include JSON
		
    def initialize()
      super()
      @jsessionid = nil
    end
		
    def login (loginemail, password)
      loginemail = remove_suffix(loginemail,'.linkedin')
      loginemail.downcase!
      html = http_post('https://www.linkedin.com/secure/login',  {'session_key'=>loginemail, 'session_password'=>password, 'session_login'=>'Sign In'})
      raise AuthenticationError, 'Bad user name or password' if html.include?('class="error"') 
    end
		
		
    def fetch_contacts (loginemail, password)
		
      login(loginemail,password)

      va = cookie_jar.get_cookie_values('http://www.linkedin.com/','JSESSIONID')
      raise UnexpectedFormatError, 'Cannot find JSESSIONID' if va.nil? || va.empty?
      @jsessionid = va[0];

			al = []
			page = 'DONT_CARE'
			pages = nil
			pagecount = 1
			max_pages = 30
			while pagecount<max_pages

				#Fetch the page
				v = Time.now.to_i
				cmd = 	"callCount=1\r\n"\
					"JSESSIONID=#{@jsessionid}\r\n"\
					"c0-scriptName=ConnectionsBrowserService\r\n"\
					"c0-methodName=getMyConnections\r\n"\
					"c0-id=#{v}\r\n"\
					"c0-param0=string:0\r\n"\
					"c0-param1=number:-1\r\n"\
					"c0-param2=string:"+CGI.escape(page)+"\r\n"\
					"c0-param3=number:5000\r\n"\
					"c0-param4=boolean:false\r\n"\
					"c0-param5=boolean:true\r\n"\
					"xml=true\r\n"
				url = "http://www.linkedin.com/dwr/exec/ConnectionsBrowserService.getMyConnections.dwr";
				html = http_request(url,'POST', cmd, 'UTF-8', {'Content-Type'=>'text/plain'})

				if pages.nil?
					pages={}
					html.scan(/var s\d+=\"([A-Z#])\";s\d+\[\d+\]=s\d+;/imsu) {
						s = $1.strip
						pages[s]=true
					}
				end

				html.scan(/;s\d+\['([A-Z#])'\]=s\d+;/imsu) {
					s = $1.strip
					pages.delete(s)
				}


				html.scan(/var s\d+=\{\};(.*?)\.profileLink=/imsu) {

					entryHtml = $1
					email = ''

					entryHtml =~ /var s\d+=("[^"]*");s\d+.emailAddress=s\d+/imsu
					unless $1.nil?
						email = JSON.parse('['+$1+']').to_s
					end

					id = nil
					if entryHtml =~ /var s\d+=(\d*);s\d+.memberId=s\d+/imsu
						id = JSON.parse('['+$1+']').to_s
					end

					email = email.strip
					if email =~ /^([+=&'\/\\?\\^\\~a-zA-Z0-9\._-])+@([a-zA-Z0-9_-])+(\.[a-zA-Z0-9_-]+)+/
						fname = ''
						lname = ''
						if entryHtml =~ /var s\d+=("[^"]*");s\d+.firstName=s\d+/imsu
							fname = JSON.parse('['+$1+']').to_s
						end
						if entryHtml =~ /var s\d+=("[^"]*");s\d+.lastName=s\d+/imsu
							lname = JSON.parse('['+$1+']').to_s
						end
						name = CGI.unescape((fname.strip + ' ' + lname.strip).strip)
						al.push(LinkedInContact.new(id,name,email))
					end
				}

				#Determine next page to retrieve
				break if pages.empty?
				page = pages.shift[0]
				pagecount = pagecount+1

			end

      al
    end
  end
  
  #LinkedIn
  DOMAIN_IMPORTERS['linkedin'] = LinkedInImporter
  
end

