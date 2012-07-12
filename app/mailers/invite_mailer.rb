class InviteMailer < ActionMailer::Base
  default from: "admin@plannto.com"
 
  def invite_friend(invitation)
    @invitation = invitation
    subject = "#{invitation.sender.name} invited you as #{@invitation.follow_type.humanize}"
    mail(:to => invitation.email, :subject => subject)
  end
 
end
