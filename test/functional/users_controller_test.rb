require File.dirname(__FILE__) + '/../test_helper'

class UsersControllerTest < ActionController::TestCase
  # User Activity, Profile and Comments
  test "correct activity for a user" do
    get :activity, :id => users(:tsmango).slug
    news_items = assigns(:news_items)
    assert_equal(3, news_items.size)
  end
  
  test "activity page loads with correct user" do
    get :activity, :id => users(:tsmango).slug
    user = assigns(:user)
    assert_equal(users(:tsmango).id, user.id)
  end
  
  test "profile page loads with correct user" do
    get :profile, :id => users(:tsmango).slug
    user = assigns(:user)
    assert_equal(users(:tsmango).id, user.id)
  end
  
  test "comments page loads with correct user" do
    get :profile, :id => users(:tsmango).slug
    user = assigns(:user)
    assert_equal(users(:tsmango).id, user.id)
  end
  
  # Relationships and Subscriptions
  test "correct followings for a user" do
    get :follows, :id => users(:john).slug
    users = assigns(:users)
    assert_equal(2, users.size)
    assert_equal([users(:gculliss).id, users(:tsmango).id], users.collect{|user| user.id})
  end
  
  test "correct followers for a user" do
    get :followers, :id => users(:john).slug
    users = assigns(:users)
    assert_equal(2, users.size)
    assert_equal([users(:jane).id, users(:tsmango).id], users.collect{|user| user.id})
  end
  
  test "correct friends for a user" do
    get :friends, :id => users(:john).slug
    users = assigns(:users)
    assert_equal(1, users.size)
    assert_equal([users(:tsmango).id], users.collect{|user| user.id})
  end
  
  test "correct subscriptions for a user" do
    get :subscriptions, :id => users(:john).slug
    channels = assigns(:channels)
    assert_equal(2, channels.size)
    assert_equal([channels('30_rock_channel').id, channels(:chuck_channel).id], channels.collect{|channel| channel.id})
  end
  
  # Redirects for non users and non members
  test "user does not exist" do
    get :activity, :id => 'does-not-exist'
    assert_redirected_to :action => 'index'
  end
  
  test "user is not a member" do
    get :activity, :id => 'chuck'
    assert_redirected_to :controller => 'channels', :action => 'show', :user => users(:chuck).slug, :channel => channels(:chuck_channel).slug
  end
end
