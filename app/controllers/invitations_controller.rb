class InvitationsController < ApplicationController
  def create
    @invitation= Invitation.new(params[:invitation])
    @invitation.sender = current_user
    @invitation.user_ip = request.remote_ip
    if @invitation.save
      InviteMailer.invite_friend(@invitation).deliver
      flash[:notice] = "Thank you, invitation sent."
    else
      flash[:notice] = "Invitation failed"
    end
    
    respond_to do|format|
      format.js
    end  
  end
  
  def accept
    invitation = Invitation.find_by_token(params[:token])
    unless invitation.blank?
      user = User.find_by_email(invitation.email)
      if user.blank?
        redirect_to new_user_registration_path(:token => invitation.token)
      else
        flash[:notice] = 'Invitation is successfully accepted.'
        sign_in(user)
        invitation.accept(user)
        redirect_to root_path
      end  
    else
      flash[:notice] = 'This is not a valid invitation or might have expired already. Please contact PlannTo adiministrator.'
      redirect_to root_url
    end
  end
end
