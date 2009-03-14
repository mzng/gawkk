require File.dirname(__FILE__) + '/../test_helper'

class AuthenticationControllerTest < ActionController::TestCase
  test "login by email address" do
    post :login, :user => {:email => 'tsmango@gmail.com', :password => 'password'}
    assert_not_nil session[:user_id]
    assert_redirected_to '/'
  end
  
  test "login by username" do
    post :login, :user => {:email => 'tsmango', :password => 'password'}
    assert_not_nil session[:user_id]
    assert_redirected_to '/'
  end
  
  test "bad user/password combination" do
    post :login, :user => {:email => 'tsmango@gmail.com', :password => 'bad password'}
    assert_nil session[:user_id]
    assert_template "login"
  end
  
  test "logout" do
    get :logout
    assert_nil session[:user_id]
    assert_redirected_to '/'
  end
end
