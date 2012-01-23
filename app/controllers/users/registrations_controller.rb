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
end