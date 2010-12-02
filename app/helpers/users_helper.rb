module UsersHelper
  def user_profile_link
    link_to "Profile", "http://#{BASE_URL}/my-profile" 
  end
end
