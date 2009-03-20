class AuthenticationController < ApplicationController
  layout 'page'
  
  def login
    if request.get?
      # Logout the current user
      session[:user_id] = nil
      
      @user = User.new
    else
      if @user = User.new(params[:user]).try_to_login
        # Setup cookies for automatic logins
        # if params[:remember]
        #   begin
        #     cookie_pass = [Array.new(9){rand(256).chr}.join].pack("m").chomp
        #     cookie_hash = Digest::MD5.hexdigest(cookie_pass + @user.salt)
        #     cookies[:gawkk_login_pass] = { :value => cookie_pass, :expires => 2.weeks.from_now }
        #     cookies[:gawkk_login] = { :value => @user.username, :expires => 2.weeks.from_now }
        #     @user.cookie_hash = cookie_hash
        #   rescue
        #   end
        # end
        
        # Update the user's last login time
        @user.last_login_at = Time.new
        @user.save
        
        # Store the logged in user's id in the session
        session[:user_id] = @user.id
        
        redirect_to '/'
      else
        flash[:notice] = 'Invalid user/password combination'
        
        @user = User.new(params[:user])
        @user.password = ''
      end
    end
  end
  
  def logout
    # Logout the current user
    session[:user_id] = nil
    
    redirect_to '/'
  end
end
