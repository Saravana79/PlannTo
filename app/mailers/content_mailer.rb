class ContentMailer < ActionMailer::Base
  default from: "\"PlannTo\" <admin@plannto.com>"
  def my_feeds_content(contents,user,followed_item_ids)
    @contents = contents
    @username = user.username
    @userfullname = user.name
    @items = Item.where('id in (?)',followed_item_ids[0..5])
    if(contents.size > 0)
    subject = "Weekly Digest - " + contents[0].title;
	else
	subject = "PlannTo digest for this week"
	end 
    mail(:to => user.email, :subject => subject)
  end
  
  def not_follow_user_content(contents,user,item_ids)
    @contents = contents
    @username = user.username
    @userfullname = user.name
    @items = Item.where('id in (?)',item_ids)
    subject = "PlannTo Top Contents"
    mail(:to => user.email, :subject => subject)
 end
 end
