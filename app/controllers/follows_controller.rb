class FollowsController < ApplicationController
  before_filter :authenticate_user!
  
  def destroy
    follow = Follow.find(params[:id])
    follow.destroy
    redirect_to :back, :notice => "Successfully unfollowed."
  end
  
  def create
    if current_user.follows.where(followable_id: params[:follow][:followable_id]).where(followable_type: params[:follow][:followable_type]).where(follow_type: params[:follow][:follow_type]).first.blank?
      current_user.follows.create(params[:follow])
      current_user.clear_user_follow_item
      if params[:follow][:followable_type]  == "User"
       UserActivity.save_user_activity(current_user, params[:follow][:followable_id],"followed","User",params[:follow][:followable_id],request.remote_ip)
      end 
    end
      
    redirect_to :back, :notice => "Successfully following."
  end
 end
