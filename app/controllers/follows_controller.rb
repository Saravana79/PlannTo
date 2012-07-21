class FollowsController < ApplicationController
  before_filter :authenticate_user!
  
  def destroy
    follow = Follow.find(params[:id])
    follow.destroy
    redirect_to :back, :notice => "Successfully unfollowed."
  end
  
  def create
    current_user.follows.create(params[:follow])
    redirect_to :back, :notice => "Successfully following."
  end
end
