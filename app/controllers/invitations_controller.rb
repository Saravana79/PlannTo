class InvitationsController < ApplicationController
  def create
    @invitation=Invitation.new(params[:invitation])
    @invitation.sender=current_user
    @invitation.user_ip=request.remote_ip
    if @invitation.save
      InviteMailer.invite_by_email(@invitation).deliver
      flash[:notice] = "Thank you, invitation sent."
    else
      flash[:notice] = "Invitation failed"
    end
    
    respond_to do|format|
      format.js
    end  
  end
end
