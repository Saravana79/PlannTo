class AccountsController < ApplicationController
  before_filter :require_authentication
  before_filter :get_user_info
  def index


  end

  def update
    if current_user.update_attributes(params[:user]) && current_user.errors.blank?
      flash[:message] = "Account update successfully"
    end      
    render :action => :index
  end

  def get_user_info
    @user = current_user
    @facebook_user = facebook_profile
  end

  def profile
    @follow_item = Follow.for_follower(current_user).where(:followable_type => ['Car', 'Mobile']).group_by(&:followable_type)
    render :layout => "product"
  end

end
