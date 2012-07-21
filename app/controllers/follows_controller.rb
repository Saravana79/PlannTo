class FollowsController < ApplicationController
  before_filter :authenticate_user!
  
  def destroy
    @follow = Follow.find(params[:id])
    @follow.destroy
    redirect_to :back, :notice => "Successfully unfollowed."
  end
end
