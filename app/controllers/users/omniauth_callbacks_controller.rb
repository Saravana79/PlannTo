class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  layout "product"
  
  def facebook
    auth = request.env["omniauth.auth"]
    user = User.where(:email => auth.info.email).last
    @user_object = user
    if user.blank?
      user = User.create_from_fb_callback(auth)
      user.follow_facebook_friends #TODO follow fb friends. Move it to background job, in case of performance issue in future
    else
      user.update_attribute('token', auth['credentials']['token'])
    end
    sign_in user
    render :layout => false
  end
end
