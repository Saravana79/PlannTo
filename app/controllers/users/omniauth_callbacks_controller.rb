class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  #def method_missing(provider)
  def facebook
    auth = request.env["omniauth.auth"]
    user = User.find_by_email(auth.info.email)
    
    if user.blank?
      user = User.create(email:auth.info.email, name:auth.extra.raw_info.name, password:Devise.friendly_token[0,20], uid:auth.uid, token:auth.credentials.token)
    else
      user.update_attribute('token', auth['credentials']['token'])  
    end
    sign_in user
    
    redirect_to root_path
  end
end
