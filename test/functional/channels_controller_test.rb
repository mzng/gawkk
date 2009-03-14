require File.dirname(__FILE__) + '/../test_helper'

class ChannelsControllerTest < ActionController::TestCase
  # Channel Stream
  test "correct user gets loaded for channel" do
    get :show, :user => users(:chuck).slug, :channel => channels(:chuck_channel).slug
    
    user = assigns(:user)
    assert_equal(users(:chuck).slug, user.slug)
  end
  
  test "correct channel gets loaded for channel" do
    get :show, :user => users(:chuck).slug, :channel => channels(:chuck_channel).slug
    
    channel = assigns(:channel)
    assert_equal(channels(:chuck_channel).slug, channel.slug)
    assert_equal(users(:chuck).id, channel.user_id)
  end
  
  test "correct videos get loaded for channel" do
    get :show, :user => users(:chuck).slug, :channel => channels(:chuck_channel).slug
    
    videos = assigns(:videos)
    assert_equal(2, videos.size)
  end
  
  # Redirects for non users and non members
  test "user does not exist" do
    get :show, :user => 'does-not-exist'
    assert_redirected_to :action => 'index'
  end
  
  test "channel does not exist" do
    get :show, :user => 'chuck', :channel => 'does-not-exist'
    assert_redirected_to :action => 'index'
  end
  
  test "user is not a feed owner" do
    get :show, :user => 'john', :channel => 'channel'
    assert_redirected_to :controller => 'users', :action => 'activity', :id => users(:john).slug
  end
end
