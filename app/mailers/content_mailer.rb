class ContentMailer < ActionMailer::Base
  default from: "admin@plannto.com"
  def my_feeds_content(contents,user)
    @contents = contents
    subject = "Latest Plannto contents"
    mail(:to => user.email, :subject => subject)
  end
 end
