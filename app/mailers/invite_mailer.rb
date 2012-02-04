class InviteMailer < ActionMailer::Base
  default from: "plannto.test@gmail.com"

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.invite_mailer.invite_by_email.subject
  #
  def invite_by_email(invitation)
    @relation=follow_type_of_user(invitation)
    subject = "#{invitation.sender.name} invited you as #{@relation}"
    @invitation = invitation
    mail(:to => invitation.email, :subject => subject)
  end
  
  def follow_type_of_user(invitation)
    if invitation.follow_type ==0
      "owner"
    elsif invitation.follow_type==1
      "buyer"
    elsif invitation.follow_type==2
      "follower"
    else
      ""
    end
  end
end
