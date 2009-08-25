class FacebookController < ApplicationController
  skip_before_filter :verify_authenticity_token, :only => [:connect]
  
  layout 'page'
  
  
  def fb_callback
    parsed = {}
    
    logger.debug Util::Facebook.config[:key]
    
    cookies.keys.select{ |k|
      k.starts_with?(Util::Facebook.config[:key] + "_")
    }.each { |key|
      parsed[key[(Util::Facebook.config[:key] + "_").size, key.size]] = cookies[key]
    }
    
    return unless parsed['session_key'] && parsed['user'] && parsed['expires'] && parsed['ss'] 
    return unless Time.at(parsed['expires'].to_s.to_f) > Time.now || (parsed['expires'] == "0")          
    
    verify_signature(parsed,cookies[Util::Facebook.config[:key]])
    
    facebook_session = Facebooker::Session.create(Util::Facebook.config[:key], Util::Facebook.config[:secret])
    facebook_session.secure_with!(parsed['session_key'], parsed['user'], parsed['expires'], parsed['ss'])
    facebook_session
    
    if facebook_session and facebook_session.user and facebook_session.user.uid
      if facebook_account = FacebookAccount.find(:first, :conditions => {:facebook_user_id => facebook_session.user.uid.to_s})
        @user = facebook_account.user
        
        # Update the user's last login time
        @user.cookie_hash = bake_cookie_for(@user)
        @user.last_login_at = Time.new
        @user.save

        # Store the logged in user's id in the session
        session[:user_id] = @user.id
        accept_outstanding_invitation
        
        redirect_to !session[:redirect_to].blank? ? session[:redirect_to] : '/'
      else
        facebook = Hash.new
        facebook[:id] = facebook_session.user.uid
        facebook[:name] = facebook_session.user.name
        facebook[:description] = facebook_session.user.about_me
        facebook[:image_small] = facebook_session.user.pic_square_with_logo
        facebook[:image_large] = facebook_session.user.pic_big
        
        session[:facebook_credentials] = facebook
        
        redirect_to :controller => 'registration', :action => 'setup_suggestions'
      end
    else
      flash[:notice] = 'The authentication failed. Please try again!'
      redirect_to '/'
    end
  rescue
    flash[:notice] = 'The authentication failed. Please try again!'
    redirect_to '/'
  end
  
  def connect
    if request.get?
      @facebook = session[:facebook_credentials]
      
      @user = User.new
      @user.send_digest_emails = true

      if !@facebook[:name].blank?
        if !@facebook[:profile_url].blank? and !@facebook[:profile_url][/^profile.php/]
          @user.username = @facebook[:profile_url].first(15).gsub(/\s/, '').gsub(/\./, '')
        else
          @user.username = @facebook[:name].first(15).gsub(/\s/, '').gsub(/\./, '')
        end
  
        attempt = 0
        while !User.valid_username?(@user.username) and attempt < 3 do
          if @user.username.length < 15
            @user.username = @user.username + rand(10).to_s
          else
            @user.username = @user.username[0, 14] + rand(10).to_s
          end
    
          attempt = attempt + 1
        end
      end
    else
      @facebook = session[:facebook_credentials]
      
      @user = User.new(params[:user])
      @user.name = @facebook[:name]
      @user.description = @facebook[:description]
      @user.ad_campaign = session[:ref]
      @user.administrator = false
      @user.feed_owner  = false
      @user.facebook    = true
      
      @user.password = Util::AuthCode.generate(32)
      @user.password_confirmation = @user.password
      
      if params[:format] == 'fbml'
        @user.email = "fb-app-user+#{Util::Slug.generate(@user.username, false)}@gawkk.com"
      end
      
      if @user.save
        # Remember this user
        @user.cookie_hash = bake_cookie_for(@user)
        @user.save
        
        # Fetch and set Facebook avatar
        Util::Avatar.fetch_from_facebook(@user, @facebook[:image_large])
        Util::Avatar.use_service_avatar(@user, 'facebook')
        
        # Store Facebook account information
        facebook_account = FacebookAccount.new
        facebook_account.user_id = @user.id
        facebook_account.facebook_user_id = @facebook[:id]
        
        if facebook_account.save
          session[:facebook_credentials] = nil
        end
        
        session[:user_id] = @user.id
        accept_outstanding_invitation
      end
      
      if params[:format] == 'fbml'
        redirect_to :controller => "videos", :action => "friends"
      else
        redirect_to :controller => "registration", :action => "setup_suggestions"
      end
    end
  end
  
  private
  # This collides with with the verify_signatures inside of the facebooker plugin
  # def verify_signature(facebook_sig_params, expected_signature)
  #   raw_string = facebook_sig_params.map{ |*args| args.join('=') }.sort.join
  #   actual_sig = Digest::MD5.hexdigest([raw_string, Util::Facebook.config[:secret]].join)
  #   raise Facebooker::Session::IncorrectSignature if actual_sig != expected_signature
  #   raise Facebooker::Session::SignatureTooOld if facebook_sig_params['time'] && Time.at(facebook_sig_params['time'].to_f) < earliest_valid_session
  #   true
  # end
end
