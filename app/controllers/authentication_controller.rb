class AuthenticationController < ApplicationController
  layout 'page'
  
  def login
    @redirect_to = (params[:redirect_to] or session[:redirect_to])
    session[:redirect_to] = (params[:redirect_to] or session[:redirect_to])
    
    if request.get?
      # Logout the current user
      session[:user_id] = nil
      
      @user = User.new
    else
      if @user = User.new(params[:user]).try_to_login
        # Setup cookies for automatic logins
        if params[:remember] == '1'
          begin
            @user.cookie_hash = bake_cookie_for(@user)
          rescue
          end
        end
        
        # Update the user's last login time
        @user.last_login_at = Time.new
        @user.save
        
        # Store the logged in user's id in the session
        session[:user_id] = @user.id
        accept_outstanding_invitation
        
        flash[:notice] = nil
        redirect_to (params[:current] and !params[:current][:path].blank?) ? params[:current][:path] : '/'
      else
        flash[:notice] = 'Invalid user/password combination'
        
        @user = User.new(params[:user])
        @user.password = ''
      end
    end
  end
  
  def logout
    # Logout the current user
    if session[:user_id]
      session[:user_id] = nil
    end
    
    redirect_to :action => 'forget_token'
  end
  
  def forget_token
    # Forget autologin cookie
    if cookies[:_gawkk_login]
      cookies.delete(:_gawkk_login)
    end
    
    redirect_to '/'
  end
end
