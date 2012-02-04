class Users::RegistrationsController < Devise::RegistrationsController
  def create
    super
    if current_user
      begin
        params[:user][:avatar][:user_id] = current_user.id
        Avatar.create(params[:user][:avatar])
      rescue
        flash[:notice] = "please upload the avatar from profile page"
      end
    end
  end
  
  def invited
      @user = User.new(:invitation_token => params[:invitation_token])
      @user.email = @user.invitation.email if @user.invitation
      respond_to do|format|
        format.html { render :new }
      end
  end
end