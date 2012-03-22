class Users::RegistrationsController < Devise::RegistrationsController
  def create
    super
  end
  
  def invited
      @user = User.new(:invitation_token => params[:invitation_token])
      @user.email = @user.invitation.email if @user.invitation
      respond_to do|format|
        format.html { render :new }
      end
  end
end