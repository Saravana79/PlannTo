class Admin::UsersController < ApplicationController
  layout "product"
   before_filter :authenticate_admin_user!
  def index
    @no_users = User.find(:all).size
    @users = User.order(:created_at).paginate(:per_page => 20,:page => params[:page])
  end

end
