class Users::SessionsController < Devise::SessionsController
  skip_before_filter :check_authentication, :store_session_url
  skip_before_filter :facebook_friends
  def new
    return redirect_to root_url unless current_user.blank?
    super
  end

end