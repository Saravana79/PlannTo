class ContentMailer < ActionMailer::Base
  default from: "admin@plannto.com"
  def my_feeds_content(contents,user,followed_item_ids)
    @contents = contents
    @username = user.username
    @items = Item.where('id in (?)',followed_item_ids[0..5])
    subject = "Latest Plannto contents"
    mail(:to => user.email, :subject => subject)
  end
 end
