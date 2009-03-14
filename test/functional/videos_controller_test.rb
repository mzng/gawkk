require File.dirname(__FILE__) + '/../test_helper'

class VideosControllerTest < ActionController::TestCase
  # All Categories Stream
  test "newest videos across all categories" do
    get :index, :popular => false
    videos = assigns(:videos)
    assert_equal(8, videos.size)
    assert_equal(videos.collect{|v| v.posted_at}.sort.reverse, videos.collect{|v| v.posted_at})
  end
  
  test "popular videos across all categories" do
    get :index, :popular => true
    videos = assigns(:videos)
    assert_equal(4, videos.size)
    assert_equal(videos.collect{|v| v.promoted_at}.sort.reverse, videos.collect{|v| v.promoted_at})
  end
  
  
  # Single Category Stream
  test "newest videos in a single category" do
    get :category, :category => 'television', :popular => false
    videos = assigns(:videos)
    assert_equal(4, videos.size)
    assert_equal(videos.collect{|v| v.posted_at}.sort.reverse, videos.collect{|v| v.posted_at})
  end
  
  test "popular videos in a single category" do
    get :category, :category => 'television', :popular => true
    videos = assigns(:videos)
    assert_equal(2, videos.size)
    assert_equal(videos.collect{|v| v.promoted_at}.sort.reverse, videos.collect{|v| v.promoted_at})
  end
  
  test "category does not exist" do
    get :category, :category => 'does-not-exist', :popular => false
    assert_redirected_to :action => 'index'
  end
  
  
  # Friends Activity Stream
  test "friends activity for logged in user" do
    login_as(users(:john))
    get :friends
    news_items = assigns(:news_items)
    assert_equal(4, news_items.size)
  end
  
  test "friends activity for no logged in user" do
    assert_nil(session[:user_id])
    get :friends
    news_items = assigns(:news_items)
    assert_equal(2, news_items.size)
  end
  
  
  # Subscriptions Videos Stream
  test "subscription videos for logged in user" do
    login_as(users(:john))
    get :subscriptions
    videos = assigns(:videos)
    assert_equal(3, videos.size)
    assert_equal(videos(:big_bang_theory).id, videos.first.id)
  end
  
  test "subscription videos for no logged in user" do
    assert_nil(session[:user_id])
    get :subscriptions
    videos = assigns(:videos)
    assert_equal(2, videos.size)
    assert_equal(videos(:chuck).id, videos.first.id)
  end
  
  
  # Single Video
  test "video discuss page loads with correct video" do
    get :discuss, :id => videos(:chuck).slug
    video = assigns(:video)
    assert_equal(videos(:chuck).id, video.id)
  end
  
  test "video does not exist" do
    get :discuss, :id => 'does-not-exist'
    assert_redirected_to :action => 'index'
  end
end
