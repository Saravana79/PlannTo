class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  require 'open-uri'
  
  def facebook
    auth = request.env["omniauth.auth"]
    user = User.find_by_email(auth.info.email)
  
    if user.blank?
      user = User.new(email:auth.info.email, name:auth.extra.raw_info.name, password:Devise.friendly_token[0,20], 
                      uid:auth.uid, token:auth.credentials.token)
      
      user.avatar = open(auth.info.image.gsub('square', 'large')) #http://graph.facebook.com/626630268/picture?type=square 
      user.save
    else
      user.update_attribute('token', auth['credentials']['token'])
    end
    sign_in user
    
    redirect_to root_path
  end
end
