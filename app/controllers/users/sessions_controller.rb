class Users::SessionsController < Devise::SessionsController
  def destroy
    super
    unauthenticate
  end
end