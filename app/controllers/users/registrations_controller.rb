class Users::RegistrationsController < Devise::RegistrationsController

  def invited
      @user = User.new(:invitation_token => params[:invitation_token])
      @user.email = @user.invitation.email if @user.invitation
      respond_to do|format|
        format.html { render :new }
      end
  end

  def after_sign_up_path_for(resource)
    root_path
  end
end