#********************************************************************************
#Copyright 2009 Octazen Solutions
#All Rights Reserved
#
#You may not use, reprint or redistribute this code without permission from
#Octazen Solutions.
#
#WWW: http://www.octazen.com
#Email: support@octazen.com
#********************************************************************************
require 'uri'
require 'net/http'
require 'net/https'
require 'logger'
require 'csv'
require 'cgi'
require 'parsedate'
require 'zlib'
require 'stringio'
require 'iconv'
require 'base64'

#Install ruby gems
# gem install htmlentities
require 'rubygems'

#From http://htmlentities.rubyforge.org/
#gem install htmlentities
require 'htmlentities'

module Octazen

  class Contact
    attr_accessor :name,:email
    def initialize (name,email)
      name = email if name.nil? || name.empty?
      @name = name
      @email = email
    end
  end


  class HttpError < StandardError; end
  class AddressBookError < StandardError; end
  class AuthenticationError < AddressBookError; end
  class UnexpectedFormatError < AddressBookError; end
  class UserInputRequiredError < AddressBookError; end
  class CaptchaError < UserInputRequiredError; end
  class UnsupportedAddressBookError < AddressBookError; end


  class Logging

    @@logger = nil

    def Logging.set_logger logger
      @@logger = logger
    end

    def Logging.debug msg
      if !@@logger.nil?
        @@logger.debug(msg)
      end
    end

    def Logging.info msg
      @@logger.info(msg) if !@@logger.nil?
    end

    def Logging.warn msg
      @@logger.warn(msg) if !@@logger.nil?
    end

    def Logging.error msg
      @@logger.error(msg) if !@@logger.nil?
    end

    def Logging.fatal msg
      @@logger.fatal(msg) if !@@logger.nil?
    end
  end


  class HtmlTools

    #Unescape html to UTF-8 form using htmlentities gem
    def HtmlTools.decode_html (html)
      return html if html.nil?
      coder = HTMLEntities.new
      coder.decode(html)
    end
  end

  class UrlTools

    def UrlTools.get_refresh_url (html)
      if html =~ /(<meta[^>]*http-equiv\s*=\s*["']?refresh["'>]?[^>]*>)/ims
        html = $1
        if html =~ /url\s*=\s*([^"'>]*)/ims
          html = HtmlTools.decode_html($1.strip)
          n = html.length
          if n>0
            c = html[0,1]
            if c=="'" || c=='"'
              if c==html[-1,1]
                html = html[1..n-2]
              else
                html = html[1..n-1]
              end
            end
          end
          return html
        else
          return ''
        end
      end
      return nil
    end

  end


  class StringTools
    def initialize()
    end

    def StringTools.compare_no_case (str1, str2)
      return 0 if str1==str2
      return 1 if str1.nil?
      return -1 if str2.nil?
      if str1==str2
        return 0
      end
      str1 = str1.downcase
      str2 = str2.downcase
      str1<=>str2
    end

    def StringTools.equals_no_case (str1, str2)
      compare_no_case(str1,str2)==0
    end
  end

  #----------------------------------------------------------------------------
  # Cookie, CookieJar
  #----------------------------------------------------------------------------

  class Cookie

    private

    #Default cookie lifespan = 20 days
    DEFAULT_LIFESPAN = (60 * 60 * 24 * 20)


    public

    attr_accessor :name,:value,:domain,:path,:expires

    def initialize ()
      @name = nil
      @value = nil
      @domain = nil
      @path = nil
      @expires = Time.now+DEFAULT_LIFESPAN
    end

    def initialize (cookiestring, uri)
      init(cookiestring,uri)
    end

    def init (cookiestring, uri)
      @expires = Time.now+DEFAULT_LIFESPAN
      uri2 = URI.parse(uri)
      @domain = '.'+uri2.host
      @path = '/'
      parts = cookiestring.split(';')
      parts.each_index { |i|
        s = parts[i]
        namevalue = s.split('=', 2)
        if namevalue.length==1
          name = s;
          value = '';
        else
          name = namevalue[0].strip
          value = namevalue[1].strip
        end
        lname = name.downcase
        if i==0
          @name=name
          @value=value
        elsif lname=='domain'
          @domain=value.strip
        elsif lname=='path'
          @path=value.strip
        elsif lname=='expires'
          #Crap - need to parse W3C date!
          begin
            @expires = Time.gm(*ParseDate::parsedate(value.strip, true)[0..4])
          rescue 
            #Ignore expiry date
          end
					#Advanced by 23 hours in case timezone is off
					@expires = @expires+(23*60*60)
        elsif lname=='secure'
          #Ignore for now
        end
      }
    end
  end

  class CookieJar
    def initialize()
      @cookies = []
    end

    def clear ()
      @cookies = []
    end

    def add_cookie (cookie)
      @cookies.each_index { |i|
        cookie1 = @cookies[i]
        domain1 = cookie1.domain
        path1 = cookie1.path
        name1 = cookie1.name
        if StringTools::equals_no_case(domain1,cookie.domain) &&
            StringTools::equals_no_case(path1,cookie.path) &&
            StringTools::equals_no_case(name1,cookie.name)
          @cookies[i]=cookie
          return
        end
      }
      @cookies.push cookie
    end

    def get_cookie_string (uri, cookiename=nil)

      uri2 = URI::parse(uri)
      path = uri2.path.nil? || uri2.path=='' ? '/' : uri2.path
      domain = '.'+uri2.host.downcase
      now = Time.now
      cookiestr = ''
      #find matching host, and then only matching path host ends with the given uri
      @cookies.each {|cookie|
        cdomain = cookie.domain.downcase
        cdomain='.'+cdomain if cdomain[0,1]!='.'
        x = domain.length-cdomain.length
        if x>=0
          ss = domain.slice(x,domain.length)
          if ss==cdomain
            # Domain matches, so now check if path matches
            if !path.index(cookie.path).nil?
              if (cookie.expires<=>now) >= 1 && (cookiename.nil? || cookiename==cookie.name)
                cookiestr << '; ' if cookiestr.length>0
                cookiestr << cookie.name
                cookiestr << '='
                cookiestr << cookie.value
              end
            end
          end
        end
      }

      cookiestr
    end

    def get_cookie_values (uri, cookiename)

      uri2 = URI.parse(uri)
      path = uri2.path.nil? || uri2.path=='' ? '/' : uri2.path
      domain = '.'+uri2.host.downcase
      now = Time.now
      values = []
      #find matching host, and then only matching path host ends with the given uri
      @cookies.each {|cookie|
        cdomain = cookie.domain.downcase
        cdomain='.'+cdomain if cdomain[0,1]!='.'
        n = domain.length
        x = n-cdomain.length
        if x>=0
          ss = domain[x..n-1]
          if ss==cdomain
            # Domain matches, so now check if path matches
            if !path.index(cookie.path).nil?
              if (cookie.expires<=>now) >= 1 && cookiename==cookie.name
                values.push cookie.value
              end
            end
          end
        end
      }

      values
    end
  end

  #----------------------------------------------------------------------------
  # HtmlFormParser
  #----------------------------------------------------------------------------

  class HtmlAttribute
    attr_accessor :name, :value
    def initialize (name=nil, value=nil)
      @name = name
      @value = value
    end
  end

  class HtmlAttributeTokenizer

    private

    def skip_whitespace
      while @i<@n
        c = @html[@i,1]
        break if c!=' ' && c!="\t" && c!="\r" && c!="\n"
        @i += 1
      end
    end


    public

    def initialize (html)
      @html = html
      @i = 0
      @n = html.length
    end


    def extract_attribute_element
      return nil if @i>@n
      quote_char = "\000"
      c = @html[@i,1]
      if c=="'" || c=='"'
        quote_char = c
        @i+=1
      end

      i1 = @i
      while @i<@n
        c = @html[@i,1]
        if quote_char=="\000"
          if c=="/" || c=="\'" || c=='"' || c=='>' || c=='=' || c==' ' || c=="\t" || c=="\r" || c=="\n"
            break
          end
        else
          if c==quote_char
            s = @html[i1..@i-1]
            @i+=1
            return HtmlTools.decode_html(s)
          end
        end
        @i+=1
      end

      if i1==@i
        return nil
      else
        return HtmlTools.decode_html(@html[i1..@i-1])
      end
    end



    def next_attribute
      name = nil
      value = nil

      skip_whitespace
      name = extract_attribute_element
      if name.nil?
        return nil
      end
      skip_whitespace

      #If next item is a "=" then it's an equals sign
      if @i<@n && @html[@i,1]=='='
        @i+=1
        skip_whitespace
        value = extract_attribute_element
      end

      return HtmlAttribute.new(name,value)
    end

  end

  class HtmlFormParser

    def HtmlFormParser.extract_forms (html, onlyhidden=true)

      al = []
      html.scan(/<form([^>]*)>(.*?)<\/form[^>]*>/imsu) {
        forminfo = $1
        formhtml = $2
        fo = HttpForm.new

        #Extract form attributes
        at = HtmlAttributeTokenizer.new(forminfo)
        while true
          a = at.next_attribute
          break if a.nil?
          a.name.downcase!
          if 'id'==a.name then fo.id = a.value
          elsif 'name'==a.name then fo.name=a.value
          elsif 'action'==a.name then fo.action=a.value
          elsif 'method'==a.name then fo.method=a.value
          elsif 'enctype'==a.name then fo.enctype=a.value
          end
        end

        #Extract form fields
        formhtml.scan(onlyhidden ? /<input\s*([^>]*type\s*=\s*(?:\"hidden\"|'hidden'|hidden)[^>]*)>/imsu : /<input\s*([^>]*)>/imsu) {
          fieldhtml = $1
          at = HtmlAttributeTokenizer.new(fieldhtml)
          name = nil
          value = ''
          while true
            a = at.next_attribute
            break if a.nil?
            a.name.downcase!
            if 'name'==a.name then name=a.value
            elsif 'value'==a.name then value=a.value
            end
          end
          if !name.nil? && name.length>0
            fo.add_field(name,value)
          end
        }

        al.push(fo)
      }
      al
    end


    def HtmlFormParser.extract_form_by_name (html, name)
      #name = name.downcase
      res = extract_forms(html)
      for fo in res
        name2 = fo.name
        unless name2.nil?
          #name2.downcase!
          if name==name2
            return fo
          end
        end
      end
      nil
    end

    def HtmlFormParser.extract_form_by_id (html, id)
      #name = name.downcase
      res = extract_forms(html)
      for fo in res
        id2 = fo.id
        unless id2.nil?
          #id2.downcase!
          if id==id2
            return fo
          end
        end
      end
      nil
    end


  end

  #----------------------------------------------------------------------------
  # HttpField, HttpForm
  #----------------------------------------------------------------------------

  class HttpField
    attr_accessor :name, :value
    def initialize (name, value)
      @name = name
      @value = value
    end
  end

  class HttpFileField < HttpField
    attr_accessor :io, :content_type, :file_name, :auto_close
    def initialize (name, value)
      super(name,value)
      @io = nil
      @auto_close = true
      @content_type = nil #'application/octet-stream'
      @file_name = nil
    end
  end

  class HttpForm

    attr_accessor :id, :name, :action, :method, :enctype

    METHOD_POST = "POST"
    METHOD_GET = "GET"
    ENCTYPE_URLENCODE = "application/x-www-form-urlencoded"
    ENCTYPE_MULTIPART = "multipart/form-data"

    def initialize
      @id = nil
      @name = nil
      @action = METHOD_GET
      @enctype = ENCTYPE_URLENCODE
      @fields = []
    end

    def add_field (field)
      @enctype = ENCTYPE_MULTIPART if field.is_a?(HttpFileField)
      @fields.push field
    end

    def add_field (name, value)
      @fields.push HttpField.new(name, value)
    end

    def set_field (name, value)
      #Delete all existing fields with the same name
      n = @fields.length
      i = 0
      while i < n
        field = @fields[i]
        if field.name==name
          @fields.delete_at(i)
          n=n-1
        else
          i=i+1
        end
      end
      #Add new field
      add_field(name,value)
    end

    def is_multipart?
      for field in @fields
        if field.is_a?(HttpFileField)
          return true
        end
      end
      false
    end

    def build_post_data
      s = ''
      for field in @fields
        s << '&' if !s.empty?
        s << CGI.escape(field.name)
        s << '='
        s << CGI.escape(field.value)
      end
      s
    end


    def build_multipart_post_data (boundary)
      s = "--#{boundary}\r\n"
      for field in @fields
        if field.is_a?(HttpFileField)
          s << "--#{boundary}\r\n"
          s << field.content_type.nil? ? "Content-Type: application/octet-stream" : "Content-Type: #{field.content_type}\r\n"
          s << "Content-Disposition: form-data; name=\"#{field.name}\"; filename=\"#{field.name}\"\r\n"
          s << "Content-Transfer-Encoding: binary\r\n\r\n"
          if !field.io.nil?
            s << file.io.read()
            field.io.close if field.auto_close
          else
            s << field.value
          end
          s << "\r\n"
        else
          s << "--#{boundary}\r\n"
          s << "Content-Type: text/plain; charset=\"utf-8\"\r\n"
          s << "Content-Disposition: form-data; name=\"#{field.name}\"\r\n"
          s << "\r\n"
          s << field.value
          s << "\r\n"
        end
      end
      s << "--#{boundary}--\r\n"
      s
    end

  end


  #----------------------------------------------------------------------------
  # WebRequestor
  #----------------------------------------------------------------------------

  class WebRequestor < Logging

    protected
    def debug msg
      Logging.debug(msg)
    end

    def info msg
      Logging.info(msg)
    end

    def warn msg
      Logging.warn(msg)
    end

    def error msg
      Logging.error(msg)
    end

    def fatal msg
      Logging.fatal(msg)
    end



    public

    attr_accessor :last_url
    attr_accessor :proxy, :proxy_port
    attr_accessor :cookie_jar
    attr_accessor :error_on_fail
    attr_accessor :last_status_code

    def initialize ()
      @last_url = ''
      @proxy = nil
      @proxy_port = nil
      @logger = nil
      @cookie_jar = CookieJar.new
      @http = Net::HTTP.new(nil,nil)
      @last_status_code = 0
      @error_on_fail = true
    end

    #    def set_logger (logger)
    #      @logger = logger
    #    end

    def make_absolute (absoluteUrl, relativeUrl)
      url = URI.parse(absoluteUrl)
      url.merge(relativeUrl).to_s
    end

    def http_post (url, postdata, defaultcharset='iso-8859-1',extraheaders=nil)
      http_request(url, 'POST', postdata, defaultcharset, extraheaders)
    end

    def http_get (url, defaultcharset='iso-8859-1',extraheaders=nil)
      http_request(url, 'GET', nil, defaultcharset, extraheaders)
    end


    def http_request (url, method='GET', postdata=nil, defaultcharset='iso-8859-1', extraheaders=nil, maxredirects=10)

      if (Octazen::USE_HTTP_1_1)
        Net::HTTP.version_1_1
      end

      #Allow up to 10 redirects?
      for redirectcount in 0..maxredirects-1

        ####################################
        #Get parts of URL
        ####################################
        url = make_absolute(@last_url,url)
        if (Octazen::DEBUG)
          debug "---------------------------------------------------------------------------------------"
          debug "Fetching (#{method}) #{url} "
        end
        uri = URI.parse(url)
        uri.scheme='http' if uri.scheme.nil?
        if uri.port.nil?
          uri.port = uri.scheme=='https' ? 443 :80
        end
        uri.path='/' if uri.path==''
        queryuri = uri.path;
        if !uri.query.nil?
          queryuri << '?' << uri.query
        end
        if !uri.fragment.nil?
          queryuri << '#' << uri.fragment
        end

        if (Octazen::DEBUG)
          debug "Path=#{queryuri}"
        end

        @http = Net::HTTP.new(uri.host,uri.port)

        #Using proxy here for testing...
        #@http = Net::HTTP.new(uri.host,uri.port,'localhost',8888)

        ####################################
        #Build the HTTP query
        ####################################

        if uri.scheme=='https'
          @http.use_ssl = true
          @http.verify_mode = OpenSSL::SSL::VERIFY_NONE;
        else
          @http.use_ssl = false
        end
        #@http.use_ssl= uri.scheme=='https'?true:false
        case method.upcase
        when 'POST' then req=Net::HTTP::Post.new(queryuri)
        when 'PUT' then req=Net::HTTP::Put.new(queryuri)
        when 'DELETE' then req=Net::HTTP::Delete.new(queryuri)
        else req=Net::HTTP::Get.new(queryuri)
        end

        if postdata.is_a?(Array)
          req.set_form_data(postdata)
        else
          req.body = postdata
          req.content_type = 'application/x-www-form-urlencoded'
        end


        ####################################
        #Add cookies for the given uri
        ####################################
        cookiestr = @cookie_jar.get_cookie_string(url)
        if cookiestr.length>0
          req['Cookie']=cookiestr
        end

        ####################################
        #Set other headers
        ####################################
        req['Host']=uri.host
        req['Accept']='text/xml,application/xml,application/xhtml+xml,text/html;q=0.9,text/plain;q=0.8,image/png,*/*;q=0.5'
        req['Accept-Encoding']='gzip' if (Octazen::USE_GZIP)
        #req['Accept-Charset']='utf-8;q=0.7,*;q=0.5','Accept-Language: en-us,en;q=0.5','Accept: text/xml,application/xml,application/xhtml+xml,text/html;q=0.9,text/plain;q=0.8,image/png,*/*;q=0.5'
        req['Accept-Charset']='us-ascii;q=0.7,*;q=0.5','Accept-Language: en-us,en;q=0.5','Accept: text/xml,application/xml,application/xhtml+xml,text/html;q=0.9,text/plain;q=0.8,image/png,*/*;q=0.5'
        req['User-Agent']='Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.8.1.11) Gecko/20071127 Firefox/2.0.0.11'
        req['Referer']=@last_url if !@last_url.empty?
        if !extraheaders.nil?
          extraheaders.each {|key, value|
            req[key]=value
          }
        end

        if (Octazen::DEBUG)
          debug '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>'
          req.each_header {|key, value|
            debug "#{key}: #{value}"
          }
          debug ''
          debug postdata unless postdata.nil?
        end

        ####################################
        #Send request!!
        ####################################

        res = @http.request(req)
        #        res = Net::HTTP.start(uri.host,uri.port) {|http|
        #          http.request(req)
        #        }

        @last_status_code = Integer(res.code)
        @last_url = url

        body = res.body

        #Add cookies to jar
        cookies = res.get_fields('Set-Cookie')
        unless cookies.nil?
          for cookie in cookies
            if (Octazen::DEBUG)
              debug "ADDCOOKIE: #{cookie}";
            end
            @cookie_jar.add_cookie(Cookie.new(cookie, url))
          end
        end

        #        @http.finish

        #Unzip body if content is gzipped
        if !body.nil? and StringTools.equals_no_case('gzip',res['Content-Encoding'])
          debug "--UNZIPPING--" if (Octazen::DEBUG)
          body_io = StringIO.new(body)
          body = Zlib::GzipReader.new(body_io).read()
        end

        #Convert to UTF-8
        ct = res['Content-Type']
        unless ct.nil?
          ct =~ /charset\s*=\s*?["']?\s*([^"';\s]*)\s*?["']?/ims
          ct = $1.nil? ? defaultcharset : $1
          body = convert_charset(body,ct,'UTF-8')
        end

        if (Octazen::DEBUG)
          debug '<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<'
          debug "#{res.code} HTTP/#{res.http_version} #{res.message}";
          res.each_header {|key, value|
            debug "#{key}: #{value}"
          }
          debug ''
          debug body unless body.nil?
        end


        case res
        when Net::HTTPSuccess then
          # OK
          return body
        when Net::HTTPRedirection then
          # Redirect
          postdata = nil
          method = 'GET'
          url = res['Location']
          debug "--> Redirect to #{url}" if (Octazen::DEBUG)
        else
          # Raise error if error should be raised!
          if @error_on_fail
            raise HttpError, "HTTP error #{res.code}"
          end
          #res.error!
          return body
        end

      end #end for

      #Raise too many redirects error
      raise HttpError, "Too many redirects"
    end

    def post_form (form)
      form.method = HttpForm::METHOD_POST
      if form.is_multipart?
        form.enctype = HttpForm::ENCTYPE_MULTIPART if form.enctype.nil?
        #TODO GENERATE RANDOM BOUNDARY! OR GUID AT LEAST
        boundary = '$$A31D0280-EECF-481c-8167-$$DE05B13A2449'
        extrahdrs = {'Content-Type'=>"multipart/form-data; boundary=\"#{boundary}\""}
        pdata = form.build_multipart_post_data(boundary)
        http_request(form.action, form.method, pdata, 'iso-8859-1', extrahdrs)
      else
        form.enctype = HttpForm::ENCTYPE_URLENCODE if form.enctype.nil?
        pdata = form.build_post_data
        http_request(form.action, form.method, pdata, 'iso-8859-1', nil)
      end
    end

    def post (url, fields)
      pdata = ''
      fields.each {|key, value|
        pdata << '&' if (!pdata.empty?)
        pdata << CGI.escape(key)
        pdata << '='
        pdata << CGI.escape(value)
      }
      http_request(url, HttpForm::METHOD_POST, pdata)
    end

    def get (url)
      http_request(url,HttpForm::METHOD_GET)
    end

    alias http_get get
    alias http_post post


    protected

    def convert_charset (text, from, to)
      return text if text.nil?
      begin
        StringTools.equals_no_case(from,to) ? text : Iconv.conv(to,from,text)
      rescue Iconv::InvalidEncoding
        #Assume is source problem. Destination always UTF-8
        #Just source as UTF-8 (or ASCII?)
        Octazen::Logging.error("Invalid transliteration from #{from}")
        text
      rescue Iconv::InvalidCharacter
        #Crap. The stream has invalid characters.
        #Do we assume stream is UTF-8 ?
        Octazen::Logging.error("Illegal character in transliteration from #{from}")
        text
      end
    end


    def login_id (email)
      email =~ /\s*(.*?)@(.*)\s*/
      return $1
    end

    def domain (email)
      email =~ /\s*(.*?)@(.*)\s*/
      return $2.downcase
    end

    def remove_suffix (str, suffix)
      n = suffix.length
      s2 = str[-n..-1]
      if s2==suffix
        str=str[0..-n-1]
      end
      str
    end

    def reduce_whitespace (str)

      #Can be simplified with gsub /[ \t\r\n]+/,' '
      sb = ''
      lastiswhitespace = true
      str.each_byte { |c|
        if c==32 || c==9 || c==10 || c==13
          next if lastiswhitespace
          lastiswhitespace = true
        else
          lastiswhitespace = false
        end
        sb << c.chr
      }
      sb.strip
    end

    def valid_email? (email)
      if email =~ /^([+=&'\/\?\^\~a-zA-Z0-9\._-])+@([a-zA-Z0-9_-])+(\.[a-zA-Z0-9_-]+)+/
        true
      else
        false
      end
    end

  end #End class


  class SimpleAddressBookImporter
    def SimpleAddressBookImporter.create_importer (email)

      return nil if email.nil?
      email = email.downcase
      email =~ /\s*(.*?)@(.*)\s*/
      domain = $2
      return nil if domain.nil?

      i = 0
      n = domain.length
      while (true)
        dom = domain[i..n-1].strip
        break if dom.nil? || dom.empty?

        #          classname = DOMAIN_IMPORTERS[dom]
        if DOMAIN_IMPORTERS.include?(dom)
          #            #If dom is just a short name with no ".", then we're passing
          #            #in different email for the domain importer.
          #            if !dom.include?('.')
          #              i1 = email.rindex('.')
          #              email = email[0..i1-1] if !i1.nil?
          #            end
          return DOMAIN_IMPORTERS[dom].new

          #            begin
          #              #importer = eval("Octazen::#{classname}.new")
          #              importer = classname.new
          #              return importer
          #            rescue NameError
          #              #No such importer...try next
          #              Logging.warn("Cannot instantiate #{classname}")
          #            end
        end
        i = domain.index('.', i+1)
        break if i.nil?
        i+=1
      end
      nil
    end

    def SimpleAddressBookImporter.fetch_contacts (email,password)
      importer = SimpleAddressBookImporter.create_importer(email)
      raise UnsupportedAddressBookError,"Unsupported domain" if importer.nil?
      return importer.fetch_contacts(email,password)
    end
  end


  
  
  class LdifRecord
    def initialize
      @map = {}
    end

    def add (field,value)
      field = field.downcase
      @map[field] = [value] if !@map.has_key? field
      @map[field].push value
    end

    def get (field)
      field = field.downcase
      return (@map.has_key? field) ? @map[field] : nil
    end

    def get_first (field)
      vals = get(field)
      return vals==nil || vals.length==0 ? nil : vals[0]
    end

    def clear
      @map = {}
    end

    def remove (field)
      field = field.downcase
      @map.delete field
    end

    def get_fields
      return @map.keys
    end
  end

  class LdifParser

    def initialize (ldif)
      @lines = ldif.split(/\r?\n/)
      @count = @lines.length
      @idx = 0

      #puts "LINES=#{@lines}, COUNT=#{@count}"

    end

    private

    def LdifParser.unescape (str)
      #No unescaping performed for now
      return str
    end
    
    
    public
    
    def next 

      r = LdifRecord.new
      prev_key = nil
      prev_value = ''
      
      while @idx<@count
        s = @lines[@idx]
        @idx = @idx+1
        if s.nil? || s.length==0
          #Reached blank line
          break if !prev_key.nil?
          #Else, continue (since we're skipping multiple blank lines)
        else
          n = s.length
          c = s[0,1]
          if c=='#'
            #Skip comment line
          elsif c==' ' || c=="\t"
            #This is a folded value
            prev_value += s[1..n-1]
          else
            #Flush out previous value
            if !prev_key.nil?
              r.add prev_key,LdifParser.unescape(prev_value)
              prev_key = nil
              prev_value = ''
            end
            
            i = s.index(':')
            unless i.nil?
              #If we have 2 colons, then it's a base64-encoded value
              
              if i+1 < n && s[i+1,1]==':'
                prev_key = s[0..i-1].strip
                prev_value = s[i+2..n-1].gsub(/^\s+/,'') #Remove space from each line (there's only 1 line here)
                #It's now in utf8...leave it
                prev_value = Base64.decode64(prev_value)
              else
                prev_key = s[0..i-1].gsub(/^\s+/,'')
                prev_value = s[i..n-1].gsub(/^\s+/,'')
              end
            end
          end
        end
      end
      
      if !prev_key.nil?
        r.add prev_key,LdifParser.unescape(prev_value)
        return r
      else
        return nil
      end

    end

  end

  
  class FileImporter
    
    def FileImporter.extract_contacts_from_ldif (ldif)
      ldp = LdifParser.new ldif
      al = []
      while true
        r = ldp.next
        break if r.nil?
        
        name = r.get_first('cn')
        email = r.get_first('mail')
        email.strip! unless email.nil?
        if !email.nil? && !email.empty?
          name = name.nil? ? nil : name.strip
          al.push(Contact.new(name,email))
        end

        email = r.get_first('mozillaSecondEmail')
        email.strip! unless email.nil?
        if !email.nil? && !email.empty?
          name = name.nil? ? nil : name.strip
          al.push(Contact.new(name,email))
        end
      end
      return al
    end
  end
  
  
  class Config

    @@config = Config.new
	
#    def initialize
#      @map = {}
#    end

    def put (key,value)
			@map = {} if @map.nil?
      @map[key] = value
    end

    def get (key,defaultvalue)
			@map = {} if @map.nil?
      return (@map.has_key? key) ? @map[key] : defaultvalue
    end

    def clear
      @map = {}
    end

    def remove (key)
			@map = {} if @map.nil?
      @map.delete key
    end


    def Config.set_instance config
      @@config = config
    end

    def Config.set_config key, value
			@@config.put key,value
    end

    def Config.get_config (key,defaultvalue)
      return @@config.get(key,defaultvalue)
    end

    def Config.get_boolean_config (key,defaultvalue)
			v = Config.get_config(key,nil)
			return v.nil? ? defaultvalue:v
    end

  end
  
end #End module