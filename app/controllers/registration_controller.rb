class RegistrationController < ApplicationController
  around_filter :load_user, :only => [:setup_services, :setup_profile, :setup_friends, :invite_friends]
  layout 'page'
  
  
  def check_validity
    @valid_username = true
    @valid_password = true
    @valid_email = false
    
    if params[:user] and !params[:user][:username].blank?
      @username = params[:user][:username]
      @valid_username = User.valid_username?(@username)
    else
      @username = 'username'
      @valid_username = nil
    end
    
    if params[:user] and !params[:user][:password].nil?
      if params[:user][:password].length < 6
        @valid_password = false
      end
    end
    
    if params[:user] and !params[:user][:email].blank?
      @valid_email = User.valid_email?(params[:user][:email])
    end
  end
  
  def register
    if !user_logged_in?
      if request.get?
        @user = User.new
        @user.send_digest_emails = true
      else
        if params[:user][:password_confirmation].nil?
          params[:user][:password_confirmation] = params[:user][:password]
        end
        
        @user = User.new(params[:user])
        @user.ad_campaign   = session[:ref]
        @user.administrator = false
        @user.feed_owner    = false
        
        if @user.save
          session[:user_id] = @user.id
          accept_outstanding_invitation
          
          redirect_to :action => "setup_services"
        end
      end
    else
      redirect_to :action => "setup_services"
    end
  end
  
  def setup_services
    # load_user or redirect
    if request.put?
      @user.twitter_username    = params[:user][:twitter_username]
      @user.friendfeed_username = params[:user][:friendfeed_username]
      @user.youtube_username    = params[:user][:youtube_username]
      @user.website_url         = params[:user][:website_url]
      @user.feed_url            = params[:user][:feed_url]
      
      if @user.save
        redirect_to :action => "setup_profile"
      end
    end
  end
  
  def setup_profile
    # load_user or redirect
    if request.get?
      @service_avatars = Util::Avatar.collect_avatars(@user)
      @age_ranges = AgeRange.collect
    else
      if params[:avatar] and params[:avatar][:for_user] != nil and params[:avatar][:for_user].class != String
        Util::Avatar.use_file_avatar(@user, params[:avatar][:for_user])
      elsif !params[:use][:service].blank?
        Util::Avatar.use_service_avatar(@user, params[:use][:service])
      end
      
      @user.name          = params[:user][:name]
      @user.age_range_id  = params[:user][:age_range_id]
      @user.sex           = params[:user][:sex]
      @user.location      = params[:user][:location]
      @user.zip_code      = params[:user][:zip_code]
      
      if @user.save
        flash[:notice] = 'Your registration is complete!'
        redirect_to :action => "setup_suggestions"
      end
    end
  end
  
  def setup_suggestions
    @user = nil
    
    if user_logged_in?
      @user = User.find(logged_in_user.id)
    end
    
    if !session[:oauth_credentials].blank? or !session[:facebook_credentials].blank?
      @user = User.new
    end
    
    if !@user.nil?
      if request.get?
        @users = collect('users', User.members.all(:conditions => {:suggested => true}, :order => 'rand()'))
        @channels = collect('channels', Channel.public.all(:conditions => {:suggested => true}, :order => 'rand()'))
      else
        params[:users].each_key do |user_id|
          if user = User.find(user_id) and params[:users][user_id] == '1'
            logged_in_user.follow(user, true)
          elsif user
            logged_in_user.unfollow(user)
          end
        end

        params[:channels].each_key do |channel_id|
          if channel = Channel.find(channel_id) and params[:channels][channel_id] == '1'
            logged_in_user.subscribe_to(channel, true)
          elsif channel
            logged_in_user.unsubscribe_from(channel)
          end
        end

        redirect_to '/'
      end
    else
      flash[:notice] = 'You must be logged in to do that.'
      redirect_to :controller => "authentication", :action => "login", :redirect_to => "/setup/suggestions"
    end
  end
  
  def setup_friends
    # load_user or redirect
    if request.get?
      @importable = Octazen::SimpleAddressBookImporter.create_importer(@user.email).nil? ? false : true
    else
      @error = ''
      @user = User.new(params[:user])
      
      if @importable = Octazen::SimpleAddressBookImporter.create_importer(@user.email)
        begin
          # Import contacts
          contacts = Octazen::SimpleAddressBookImporter.fetch_contacts(@user.email, @user.password)
          
          # Remove any contacts without a valid email address
          @contacts = Array.new
          contacts.each do |contact|
            @contacts << contact if contact.email.match(/^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i)
          end
          
          # Sort the remaining, valid contacts
          Util::Sort.sort_contacts(@contacts, 0, @contacts.size - 1)
          
          # Move any contact with a name not from A to Z to the end of the Array
          if @contacts.size > 0
            count = 0
            while !('A'..'Z').include?(@contacts[0].name.first(1).upcase) and count < @contacts.size
              @contacts << @contacts.delete_at(0)
              count += 1
            end
          end
          
          # Build character list and confirm whether or not each character has related contacts
          @characters = (('A'..'Z').to_a << '#')
          @first_characters = Hash.new
          @contacts.each do |contact|
            if @characters.include?(contact.name.first(1).upcase)
              @first_characters[contact.name.first(1).upcase] = true
            else
              @first_characters['#'] = true
            end
          end
          
          # Collect existing members
          @current_members = Hash.new
          User.find(:all, :conditions => ['lower(email) IN (?)', @contacts.collect{|contact| contact.email.downcase}]).each do |user|
            @current_members[user.email.downcase] = user
          end
          
        rescue Octazen::AuthenticationError => err
          @error = "The email address or password you entered is incorrect. Please try again."
          @importable = true
          @user.password = ''
        rescue
          @error = "Whoops, it looks like something broke! Please try again."
          @importable = true
          @user.password = ''
        end
      else
        @error = "We don't support that email address. Please try again or just send the link below to your friends."
        @user = User.new
      end
    end
  end
  
  def invite_friends
    recipients = Array.new
    params[:email_address].each do |key, value|
      recipients << key if value == '1' and key.match(/^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i)
    end
    
    if recipients.size > 0
      current_members = Hash.new
      User.find(:all, :conditions => ['lower(email) IN (?)', recipients.collect{|recipient| recipient.downcase}]).each do |user|
        current_members[user.email.downcase] = user
      end
    
      spawn do
        recipients.each do |email_address|
          if current_members[email_address].nil?
            Invitation.create :host_id => logged_in_user.id, :invitee_email => email_address, :invited_at => Time.now
          else
            logged_in_user.friend(current_members[email_address])
          end
        end
      end
      
      if (recipients.size - current_members.size) == 0
        flash[:notice] = "Good work! You've started following #{current_members.size} #{current_members.size == 1 ? 'person' : 'people'}!"
      elsif (recipients.size - current_members.size) == 1
        flash[:notice] = "Good work! That friend has been invited to join you on Gawkk!"
      else
        flash[:notice] = "Good work! Those #{recipients.size - current_members.size} friends have been invited to join you on Gawkk!"
      end
    else
      flash[:notice] = "If you decide that you'd like to invite your friends to join you on Gawkk, just head back to the <a href=\"/setup/friends\">Find Your Friends</a> page."
    end
    
    redirect_to '/'
  end
  
  def invitation_test
    if Rails.env.development?
      invitation = Invitation.new
      invitation.host_id = logged_in_user.id
      invitation.invitee_email = 'nmango@gmail.com'

      render :text => InvitationMailer.create_invitation(invitation).body
    else
      redirect_to :action => 'setup_friends'
    end
  end
  
  def confirm_domain
    @importable = (params[:email.blank?] or !Util::Email.valid?(params[:email]) or !Octazen::SimpleAddressBookImporter.create_importer(params[:email]).nil?) ? true : false
  end
  
  private
  def load_user
    if user_logged_in? and @user = User.find(logged_in_user.id)
      yield
    else
      flash[:notice] = 'You must be logged in to do that.'
      redirect_to :controller => "authentication", :action => "login"
    end
  end
end
