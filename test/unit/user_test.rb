require File.expand_path(File.dirname(__FILE__) + '/../test_helper')

class UserTest < ActiveSupport::TestCase
  test "correct followings ids are collected" do
    assert_equal([1, 6], users(:john).followings_ids.sort)
  end
  
  test "correct subscribed channel ids are collected" do
    assert_equal([3, 4], users(:john).subscription_ids.sort)
  end
end
