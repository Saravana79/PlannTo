class Users::SessionsController < Devise::SessionsController

  def new
    return redirect_to root_url unless current_user.blank?
    super
  end

end